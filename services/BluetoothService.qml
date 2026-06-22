pragma Singleton

import QtQuick
import Quickshell.Bluetooth

QtObject {
    id: root

    property Connections _adapterConnections: Connections {
        function onDiscoveringChanged() {
            root.updateStatus();
        }
        function onEnabledChanged() {
            root.updateStatus();
        }
        function onStateChanged() {
            root.updateStatus();
        }

        ignoreUnknownSignals: true
        target: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter : null
    }
    property Connections _defConnections: Connections {
        function onDefaultAdapterChanged() {
            root.updateStatus();
        }

        ignoreUnknownSignals: true
        target: Bluetooth
    }
    property Connections _devicesConnections: Connections {
        function onValuesChanged() {
            root.updateStatus();
        }

        ignoreUnknownSignals: true
        target: Bluetooth.devices
    }
    property string connectedDeviceName: ""
    property int connectedDevicesCount: 0
    property bool hasBluetooth: false
    property bool isEnabled: false
    property bool isScanning: false
    property string statusName: "Searching..."

    function toggle() {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
        }
    }
    function updateStatus() {
        let adp = Bluetooth.defaultAdapter;

        if (!adp) {
            root.hasBluetooth = false;
            root.isEnabled = false;
            root.isScanning = false;
            root.statusName = "There is no hardware";
            root.connectedDevicesCount = 0;
            root.connectedDeviceName = "";
            return;
        }

        root.hasBluetooth = true;
        root.isEnabled = adp.enabled;
        root.isScanning = adp.discovering;

        if (adp.state === BluetoothAdapterState.Disabled) {
            root.statusName = "Closed";
            root.connectedDevicesCount = 0;
            root.connectedDeviceName = "";
            return;
        } else if (adp.state === BluetoothAdapterState.Blocked) {
            root.statusName = "Blocked";
            root.connectedDevicesCount = 0;
            return;
        } else if (adp.state === BluetoothAdapterState.Enabling) {
            root.statusName = "Enable...";
            return;
        } else if (adp.state === BluetoothAdapterState.Disabling) {
            root.statusName = "Disable...";
            return;
        }

        let count = 0;
        let firstName = "";

        if (Bluetooth.devices && Bluetooth.devices.values) {
            for (let dev of Bluetooth.devices.values) {
                if (dev.connected) {
                    count++;
                    if (firstName === "") {
                        firstName = dev.name !== "" ? dev.name : dev.deviceName;
                    }
                }
            }
        }

        root.connectedDevicesCount = count;
        root.connectedDeviceName = firstName;

        if (count === 0) {
            root.statusName = root.isScanning ? "Searching..." : "Disconnected";
        } else if (count === 1) {
            root.statusName = firstName;
        } else {
            root.statusName = count + " Devices";
        }
    }

    Component.onCompleted: updateStatus()
}
