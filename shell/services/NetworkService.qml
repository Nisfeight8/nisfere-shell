pragma Singleton

import QtQuick
import Quickshell.Networking

QtObject {
    id: root

    property int __deviceCount: 0
    property Connections _devicesConnections: Connections {
        function onValuesChanged() {
            root.scanHardware();
        }

        target: Networking.devices
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
        if (!Networking.devices || !Networking.devices.values)
            return;

        let foundWifi = null;
        let foundEth = null;

        for (let dev of Networking.devices.values) {
            if (dev.type === DeviceType.Wifi && !foundWifi) {
                foundWifi = dev;
                dev.scannerEnabled = true;
            } else if (dev.type === DeviceType.Wired && !foundEth) {
                foundEth = dev;
            }

            if (foundWifi && foundEth)
                break;
        }

        wifiService.device = foundWifi;
        ethernetService.device = foundEth;

        wifiService.updateStatus();
        ethernetService.updateStatus();
    }

    Component.onCompleted: {
        root.scanHardware();
    }
    property QtObject _ethernetService: QtObject {
        id: ethernetService

        property Connections _connectStatus: Connections {
            function onConnectedChanged() {
                ethernetService.updateStatus();
            }
            function onHasLinkChanged() {
                ethernetService.updateStatus();
            }
            function onStateChanged() {
                ethernetService.updateStatus();
            }

            ignoreUnknownSignals: true
            target: ethernetService.device
        }
        property bool available: !!device
        property bool connected: device ? device.connected : false
        property QtObject device: null
        property bool hasLink: device ? device.hasLink : false
        property int linkSpeed: device ? device.linkSpeed : 0
        property QtObject network: device ? device.network : null
        property string statusName: "There is no hardware"

        function connect() {
            if (network) {
                console.log("Enable Ethernet...");
                network.connect();
            }
        }
        function disconnect() {
            if (network) {
                console.log("Disable Ethernet...");
                network.disconnect();
            }
        }
        function toggle() {
            if (network) {
                if (connected) {
                    disconnect();
                } else {
                    connect();
                }
            }
        }
        function updateStatus() {
            if (!device) {
                statusName = "There is no hardware";
            } else if (!hasLink) {
                statusName = "Cable disconnected";
            } else if (device.connected) {
                statusName = "Connected (" + linkSpeed + " Mbps)";
            } else if (device.state === ConnectionState.Connecting) {
                statusName = "Connecting...";
            } else {
                statusName = "Disconnected";
            }
        }
    }
    property Connections _networkConnections: Connections {
        function onWifiEnabledChanged() {
            wifiService.updateStatus();
        }

        target: Networking
    }

    // ==========================================
    // 3. WI-FI SUB-SERVICE
    // ==========================================
    property QtObject _wifiService: QtObject {
        id: wifiService

        property QtObject pendingNetwork: null
        signal errorOccurred(string ssid, string errorMessage)
        property Connections _pendingNetworkConnections: Connections {
            target: wifiService.pendingNetwork
            ignoreUnknownSignals: true

            function onConnectionFailed(reason) {
                console.log("Connection failed with reason code:", reason);

                if (wifiService.pendingNetwork) {
                    let failedSsid = wifiService.pendingNetwork.name;
                    wifiService.pendingNetwork.forget();
                    wifiService.pendingNetwork = null;
                    wifiService.statusName = "Disconnected";
                    wifiService.errorOccurred(failedSsid, "Wrong Password");
                }
            }

            function onConnectedChanged() {
                if (wifiService.pendingNetwork && wifiService.pendingNetwork.connected) {
                    wifiService.pendingNetwork = null;
                }
            }
        }

        property Connections _wifiConnections: Connections {
            function onConnectedChanged() {
                wifiService.updateStatus();
            }
            function onStateChanged() {
                wifiService.updateStatus();
            }

            ignoreUnknownSignals: true
            target: wifiService.device
        }
        property Connections _wifiNetworks: Connections {
            target: wifiService.device.networks

            function onObjectInsertedPost(object, index) {
                wifiService.updateStatus();
            }

            function onObjectRemovedPost(object, index) {
                wifiService.updateStatus();
            }
        }

        property bool available: !!device
        property bool connected: device ? device.connected : false
        property QtObject device: null
        property string statusName: "Searching..."
        property double netStrength: 0
        function connectTo(ssid, password = "") {
            if (!device || !device.networks || !device.networks.values)
                return;

            for (let net of device.networks.values) {
                if (net.name === ssid) {
                    console.log("An attempt is being made to connect to:", ssid);

                    pendingNetwork = net;

                    if (password !== "") {
                        net.connectWithPsk(password);
                    } else {
                        net.connect();
                    }
                    updateStatus();
                    return;
                }
            }
            console.log("The network", ssid, "not found in the list!");
        }

        function disconnect() {
            if (device) {
                console.log("Disconnect from the current Wi-Fi...");
                device.disconnect();
                updateStatus();
            }
        }

        function forgetNetwork(ssid) {
            if (!device || !device.networks || !device.networks.values)
                return;

            for (let net of device.networks.values) {
                if (net.name === ssid) {
                    console.log("Delete network profile:", ssid);
                    net.forget();
                    updateStatus();
                    return;
                }
            }
        }

        function toggle() {
            Networking.wifiEnabled = !Networking.wifiEnabled;
            updateStatus();
        }

        function updateStatus() {
            if (!device) {
                statusName = "There is no hardware";
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

            let found = false;
            if (device.networks && device.networks.values) {
                for (let net of device.networks.values) {
                    if (net && net.connected) {
                        statusName = net.name;
                        netStrength = net.signalStrength;
                        found = true;
                        break;
                    }
                }
            }
            if (!found)
                statusName = "Connected";
        }
    }
}
