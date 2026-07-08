pragma Singleton
import QtQuick
import Quickshell.Networking

QtObject {
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
        wifiService.updateStatus();
        ethernetService.updateStatus();
    }

    Component.onCompleted: root.scanHardware()

    property Connections _networkConnections: Connections {
        target: Networking
        function onWifiEnabledChanged() {
            wifiService.updateStatus();
        }
    }

    // ── Ethernet sub-service ──────────────────────────────────────
    property QtObject _ethernetService: QtObject {
        id: ethernetService

        property bool available: !!device
        property bool connected: device ? device.connected : false
        property QtObject device: null
        property bool hasLink: device ? device.hasLink : false
        property int linkSpeed: device ? device.linkSpeed : 0
        property QtObject network: device ? device.network : null
        property string statusName: "No hardware"

        property Connections _status: Connections {
            target: ethernetService.device
            ignoreUnknownSignals: true

            // _init: skip the first call (hardware detection on startup)
            property bool _init: false

            function onConnectedChanged() {
                let wasInit = _init;
                if (!_init)
                    _init = true;
                ethernetService.updateStatus();
                if (!wasInit)
                    return;
                if (ethernetService.device.connected)
                    root.ethernetConnected(ethernetService.statusName);
                else
                    root.ethernetDisconnected();
            }
            function onHasLinkChanged() {
                ethernetService.updateStatus();
            }
            function onStateChanged() {
                ethernetService.updateStatus();
            }
        }

        function updateStatus() {
            if (!device) {
                statusName = "No hardware";
                return;
            }
            if (!hasLink) {
                statusName = "Cable disconnected";
                return;
            }
            if (device.connected) {
                statusName = "Connected (" + linkSpeed + " Mbps)";
                return;
            }
            if (device.state === ConnectionState.Connecting) {
                statusName = "Connecting...";
                return;
            }
            statusName = "Disconnected";
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

        property bool available: !!device
        property bool connected: device ? device.connected : false
        property QtObject device: null
        property string statusName: "Searching..."
        property double netStrength: 0

        property Connections _conn: Connections {
            target: wifiService.device
            ignoreUnknownSignals: true

            // _init: skip the first call (hardware detection on startup)
            property bool _init: false

            function onConnectedChanged() {
                let wasInit = _init;
                if (!_init)
                    _init = true;
                wifiService.updateStatus();
                if (!wasInit)
                    return;
                if (wifiService.device.connected)
                    root.wifiConnected(wifiService.statusName);
                else
                    root.wifiDisconnected();
            }
            function onStateChanged() {
                wifiService.updateStatus();
            }
        }

        property Connections _pendingConn: Connections {
            target: wifiService.pendingNetwork
            ignoreUnknownSignals: true
            function onConnectionFailed(reason) {
                if (!wifiService.pendingNetwork)
                    return;
                let ssid = wifiService.pendingNetwork.name;
                wifiService.pendingNetwork.forget();
                wifiService.pendingNetwork = null;
                wifiService.statusName = "Disconnected";
                wifiService.errorOccurred(ssid, "Wrong Password");
            }
            function onConnectedChanged() {
                if (wifiService.pendingNetwork?.connected)
                    wifiService.pendingNetwork = null;
            }
        }

        property Connections _networks: Connections {
            target: wifiService.device?.networks
            function onObjectInsertedPost() {
                wifiService.updateStatus();
            }
            function onObjectRemovedPost() {
                wifiService.updateStatus();
            }
        }

        function updateStatus() {
            if (!device) {
                statusName = "No hardware";
                return;
            }
            if (!Networking.wifiEnabled) {
                statusName = "Closed";
                return;
            }
            if (!device.connected) {
                statusName = (device.state === ConnectionState.Connecting) ? "Connecting..." : "Disconnected";
                return;
            }
            if (!device.networks?.values) {
                statusName = "Connected";
                return;
            }
            for (let net of device.networks.values) {
                if (net?.connected) {
                    statusName = net.name;
                    netStrength = net.signalStrength;
                    return;
                }
            }
            statusName = "Connected";
        }

        function connectTo(ssid, password = "") {
            if (!device?.networks?.values)
                return;
            for (let net of device.networks.values) {
                if (net.name === ssid) {
                    pendingNetwork = net;
                    password !== "" ? net.connectWithPsk(password) : net.connect();
                    updateStatus();
                    return;
                }
            }
        }
        function disconnect() {
            device?.disconnect();
            updateStatus();
        }
        function toggle() {
            Networking.wifiEnabled = !Networking.wifiEnabled;
            updateStatus();
        }
        function forgetNetwork(ssid) {
            if (!device?.networks?.values)
                return;
            for (let net of device.networks.values)
                if (net.name === ssid) {
                    net.forget();
                    updateStatus();
                    return;
                }
        }
    }
}
