pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    // Guards — prevent firing on initial property load at startup
    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => {
        root._ready = true;
    })

    // ── notify-send ───────────────────────────────────────────────
    property Process _proc: Process {
        running: false
        onExited: running = false
    }

    function send(title, body, icon, urgency) {
        _proc.command = ["notify-send", "--app-name", "Nisfere", "--icon", icon ?? "preferences-desktop", "--urgency", urgency ?? "normal", "--expire-time", "4000", title, body ?? ""];
        _proc.running = true;
    }

    // ── Theme & Wallpaper ─────────────────────────────────────────
    property Connections themeCon: Connections {
        target: ThemeActions

        function onWallpaperSet(success, path) {
            if (!success)
                return;
            let name = path.split("/").pop().replace(/\.[^.]+$/, "");
            // Use the actual image as notification icon
            root.send("Wallpaper", name, path);
        }

        function onThemeSet(success, name) {
            if (!success)
                return;
            root.send("Theme", name + "  ·  " + Colors.mode, "preferences-desktop-theme");
        }
    }

    // ── Network — watch property changes (no custom signals) ──────
    property Connections netCon: Connections {
        target: NetworkService

        function onWifiConnected(ssid) {
            root.send("Wi-Fi", ssid, "network-wireless");
        }
        function onWifiDisconnected() {
            root.send("Wi-Fi", "Disconnected", "network-wireless-offline", "low");
        }
        function onEthernetConnected(details) {
            root.send("Ethernet", details, "network-wired");
        }
        function onEthernetDisconnected() {
            root.send("Ethernet", "Disconnected", "network-wired-offline", "low");
        }
    }   

    // ── Bluetooth — watch connectedDevicesCount ───────────────────
    property Connections bluetoothCon: Connections {
        target: BluetoothService

        property int _prevCount: 0
        property bool _prevEnabled: false

        function onConnectedDevicesCountChanged() {
            if (!root._ready)
                return;
            let curr = BluetoothService.connectedDevicesCount;
            if (curr > _prevCount)
                root.send("Bluetooth", BluetoothService.connectedDeviceName + " connected", "bluetooth-active");
            else if (curr < _prevCount && _prevCount > 0)
                root.send("Bluetooth", "Device disconnected", "bluetooth-disabled", "low");
            _prevCount = curr;
        }

        function onIsEnabledChanged() {
            if (!root._ready)
                return;
            if (BluetoothService.isEnabled)
                root.send("Bluetooth", "Enabled", "bluetooth-active", "low");
            else
                root.send("Bluetooth", "Disabled", "bluetooth-disabled", "low");
        }
    }
}
