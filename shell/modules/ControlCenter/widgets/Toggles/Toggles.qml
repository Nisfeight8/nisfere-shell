import QtQuick
import QtQuick.Layouts

import qs.core
import qs.services
import "widgets"

GridLayout {
    id: grid
    Layout.fillWidth: true
    columnSpacing: 10
    columns: 2
    rowSpacing: 10

    property var activeWidgets: []

    // Was `source: "widgets/Ethernet.qml"` (a raw string path) — the
    // only place in the whole project loading QML this way instead of
    // sourceComponent + a real import. Raw string-path Loader.source
    // means these 8 files were never validated at parse/compile time,
    // only whenever that specific Loader happened to activate — same
    // class of issue the Quickshell docs warn about for "root
    // imports" breaking LSP tooling. Proper Component references
    // instead, via a normal "widgets" import.
    Component {
        id: ethernetComp
        Ethernet {}
    }
    Component {
        id: wifiComp
        Wifi {}
    }
    Component {
        id: bluetoothComp
        Bluetooth {}
    }
    Component {
        id: themeToggleComp
        ThemeToggle {}
    }
    Component {
        id: keyboardToggleComp
        KeyboardToggle {}
    }
    Component {
        id: dndComp
        Dnd {}
    }
    Component {
        id: nightLightComp
        NightLight {}
    }
    Component {
        id: powerProfileComp
        PowerProfile {}
    }

    function updateWidgets() {
        var items = [
            {
                comp: ethernetComp,
                active: NetworkService.hasEthernet
            },
            {
                comp: wifiComp,
                active: NetworkService.hasWifi
            },
            {
                comp: bluetoothComp,
                active: BluetoothService.hasBluetooth
            },
            {
                comp: themeToggleComp,
                active: true
            },
            {
                comp: keyboardToggleComp,
                active: KeyboardService.availableLayouts.length > 1
            },
            {
                comp: dndComp,
                active: true
            },
            {
                comp: nightLightComp,
                active: true
            },
            {
                comp: powerProfileComp,
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
    Connections {
        target: KeyboardService
        function onAvailableLayoutsChanged() {
            updateWidgets();
        }
    }
    Component.onCompleted: updateWidgets()

    Repeater {
        model: grid.activeWidgets

        Loader {
            active: true
            asynchronous: false
            sourceComponent: modelData.comp
            Layout.fillWidth: true
            Layout.preferredHeight: 80
        }
    }
}
