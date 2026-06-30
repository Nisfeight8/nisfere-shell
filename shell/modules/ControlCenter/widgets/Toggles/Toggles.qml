import QtQuick
import QtQuick.Layouts

import qs.core
import qs.services

GridLayout {
    id: grid
    Layout.fillWidth: true
    columnSpacing: 10
    columns: 2
    rowSpacing: 10

    property var activeWidgets: []

    function updateWidgets() {
        var items = [
            {
                source: "widgets/Ethernet.qml",
                active: NetworkService.hasEthernet
            },
            {
                source: "widgets/Wifi.qml",
                active: NetworkService.hasWifi
            },
            {
                source: "widgets/Bluetooth.qml",
                active: BluetoothService.hasBluetooth
            },
            {
                source: "widgets/Dnd.qml",
                active: true
            },
            {
                source: "widgets/NightLight.qml",
                active: true
            },
            {
                source: "widgets/PowerProfile.qml",
                active: true
            }
        ];

        var filtered = items.filter(function (item) {
            return item.active;
        });

        if (activeWidgets.length !== filtered.length) {
            activeWidgets = filtered;
        }
    }

    Connections {
        target: NetworkService
        function onHasEthernetChanged() {
            updateWidgets();
        }
        function onHasWifiChanged() {
            updateWidgets();
        }
    }
    Connections {
        target: BluetoothService
        function onHasBluetoothChanged() {
            updateWidgets();
        }
    }
    Component.onCompleted: updateWidgets()

    Repeater {
        model: grid.activeWidgets

        Loader {
            active: true
            asynchronous: false
            source: modelData.source
            Layout.fillWidth: true
            Layout.preferredHeight: 80
        }
    }
}
