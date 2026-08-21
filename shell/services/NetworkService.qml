pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    // ── Public signals ────────────────────────────────────────────
    signal wifiConnected(string ssid)
    signal wifiDisconnected
    signal ethernetConnected(string details)
    signal ethernetDisconnected

    // ── Hardware scan ─────────────────────────────────────────────
    property Connections _devicesConnections: Connections {
        target: Networking.devices
        function onValuesChanged() {
            root.scanHardware();
        }
    }

    property alias ethernet: ethernetService
    readonly property string ethernetName: ethernet.statusName
    readonly property bool hasEthernet: ethernet.available
    readonly property bool hasWifi: wifi.available
    readonly property bool isEthernetConnected: ethernet.connected
    readonly property bool isWifiConnected: wifi.connected
    property alias wifi: wifiService
    property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property string wifiName: wifi.statusName

    function scanHardware() {
        if (!Networking.devices?.values)
            return;
        let foundWifi = null, foundEth = null;
        for (let dev of Networking.devices.values) {
            if (dev.type === DeviceType.Wifi && !foundWifi) {
                foundWifi = dev;
                dev.scannerEnabled = true;
            }
            if (dev.type === DeviceType.Wired && !foundEth)
                foundEth = dev;
            if (foundWifi && foundEth)
                break;
        }
        wifiService.device = foundWifi;
        ethernetService.device = foundEth;
    }

    Component.onCompleted: root.scanHardware()

    // ── Ethernet sub-service ──────────────────────────────────────
    property QtObject _ethernetService: QtObject {
        id: ethernetService

        property QtObject device: null
        readonly property bool available: !!device
        readonly property bool connected: device ? device.connected : false
        readonly property bool hasLink: device ? device.hasLink : false
        readonly property int linkSpeed: device ? device.linkSpeed : 0
        readonly property QtObject network: device ? device.network : null

        // Declarative — reads device.connected/hasLink/state/linkSpeed
        // directly inside the binding, so it's automatically correct
        // whenever any of them change, with no manual Connections
        // wiring needed for THIS purpose. A wired device only ever has
        // one connection at a time, so it doesn't have the "switch
        // between two already-known networks" gap wifi has below.
        readonly property string statusName: {
            if (!device)
                return "No hardware";
            if (!hasLink)
                return "Cable disconnected";
            if (device.connected)
                return "Connected (" + linkSpeed + " Mbps)";
            if (device.state === ConnectionState.Connecting)
                return "Connecting...";
            return "Disconnected";
        }

        // Signals are a side effect, not a value — can't be a pure
        // binding, still needs an imperative trigger. Kept minimal:
        // this ONLY fires the public signal, the actual displayed
        // status above is already correct via the binding regardless
        // of whether this fires.
        property Connections _signalTrigger: Connections {
            target: ethernetService.device
            ignoreUnknownSignals: true
            function onConnectedChanged() {
                if (ethernetService.device.connected)
                    root.ethernetConnected(ethernetService.statusName);
                else
                    root.ethernetDisconnected();
            }
        }

        function connect() {
            network?.connect();
        }
        function disconnect() {
            network?.disconnect();
        }
        function toggle() {
            connected ? disconnect() : connect();
        }
    }

    // ── Wi-Fi sub-service ─────────────────────────────────────────
    property QtObject _wifiService: QtObject {
        id: wifiService

        property QtObject pendingNetwork: null
        signal errorOccurred(string ssid, string errorMessage)

        property QtObject device: null
        readonly property bool available: !!device
        readonly property bool connected: device ? device.connected : false

        // Was an imperative for-loop inside updateStatus(), only ever
        // re-run by the networks list's own onObjectInsertedPost/
        // onObjectRemovedPost (list membership changing) or the
        // device's connected/state changing. Neither fires when you
        // switch from one ALREADY-KNOWN network to another while the
        // device itself stays continuously "connected" throughout —
        // so statusName kept showing the PREVIOUS network's name after
        // switching. Declarative here instead: reading net.connected
        // for every network inside this binding registers each one as
        // a dependency automatically, so it's correct regardless of
        // which specific property actually changed.
        readonly property var _connectedNetwork: {
            if (!device || !device.networks || !device.networks.values)
                return null;
            for (const net of device.networks.values) {
                if (net && net.connected)
                    return net;
            }
            return null;
        }
        readonly property double netStrength: _connectedNetwork ? _connectedNetwork.signalStrength : 0

        readonly property string statusName: {
            if (!device)
                return "No hardware";
            if (!Networking.wifiEnabled)
                return "Closed";
            if (!device.connected)
                return (device.state === ConnectionState.Connecting) ? "Connecting..." : "Disconnected";
            if (_connectedNetwork)
                return _connectedNetwork.name;
            return "Connected";
        }

        // Signal side-effect only — same reasoning as ethernet's own
        // _signalTrigger above. Doesn't re-fire on an already-connected
        // device switching to a DIFFERENT network (device.connected
        // never toggles false in that case) — same limitation the
        // original code already had; flagged here rather than silently
        // "fixed", since whether wifiConnected should re-fire with the
        // new SSID in that case is a product decision, not obviously
        // implied by the bug you reported.
        property Connections _signalTrigger: Connections {
            target: wifiService.device
            ignoreUnknownSignals: true
            function onConnectedChanged() {
                if (wifiService.device.connected)
                    root.wifiConnected(wifiService.statusName);
                else
                    root.wifiDisconnected();
            }
        }

        property Connections _pendingConn: Connections {
            target: wifiService.pendingNetwork
            ignoreUnknownSignals: true
            function onConnectionFailed(reason) {
                if (!wifiService.pendingNetwork)
                    return;
                const ssid = wifiService.pendingNetwork.name;

                // CONFIRMED (not just assumed) via the wiki's own
                // WifiNetwork.connectWithPsk() doc: "If the PSK is
                // wrong, a Network.connectionFailed() signal will be
                // emitted with NoSecrets." — this is the one, specific
                // reason that actually means "the password was wrong",
                // so it's the only one that forgets the saved network.
                // Every other reason is an infrastructure/timing issue
                // (supplicant failure, auth timeout, network out of
                // range, supplicant disconnect) that has nothing to do
                // with whether the saved password is correct —
                // forgetting the network for those would throw away a
                // perfectly good saved password for no reason, and the
                // old blanket "Wrong Password" message actively lied
                // about why it failed in every one of these cases.
                let message;
                let shouldForget = false;
                switch (reason) {
                case ConnectionFailReason.NoSecrets:
                    message = "Wrong Password";
                    shouldForget = true;
                    break;
                case ConnectionFailReason.WifiNetworkLost:
                    message = "Network out of range";
                    break;
                case ConnectionFailReason.WifiAuthTimeout:
                    message = "Authentication timed out — try again";
                    break;
                case ConnectionFailReason.WifiClientFailed:
                case ConnectionFailReason.WifiClientDisconnected:
                    message = "Wi-Fi connection failed — try again";
                    break;
                default:
                    message = "Connection failed — try again";
                }

                if (shouldForget)
                    wifiService.pendingNetwork.forget();
                wifiService.pendingNetwork = null;
                wifiService.errorOccurred(ssid, message);
            }
            function onConnectedChanged() {
                if (wifiService.pendingNetwork?.connected)
                    wifiService.pendingNetwork = null;
            }
        }

        function connectTo(ssid, password = "") {
            if (!device?.networks?.values)
                return;
            for (let net of device.networks.values) {
                if (net.name === ssid) {
                    pendingNetwork = net;
                    password !== "" ? net.connectWithPsk(password) : net.connect();
                    return;
                }
            }
        }
        function disconnect() {
            device?.disconnect();
        }
        function toggle() {
            Networking.wifiEnabled = !Networking.wifiEnabled;
        }
        function forgetNetwork(ssid) {
            if (!device?.networks?.values)
                return;
            for (let net of device.networks.values)
                if (net.name === ssid) {
                    net.forget();
                    return;
                }
        }
    }
}
