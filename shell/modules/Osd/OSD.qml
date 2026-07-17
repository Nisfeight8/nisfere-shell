import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

PanelWindow {
    id: osd

    // ── OSD state ─────────────────────────────────────────────────────────
    property string osdType: "volume"   // "volume" | "mic" | "brightness" | "media" | "battery" | "keyboard" | "screenshot"
    property string osdTitle: "Volume"
    property string osdSubtitle: ""     // π.χ. track artist, ή full layout name
    property real osdValue: 0.0       // 0.0–1.0 (or raw countdown int for "screenshot")
    property bool osdMuted: false     // muted / paused / off state

    readonly property bool showBar: osdType === "volume" || osdType === "mic" || osdType === "brightness" || osdType === "battery"
    readonly property bool showCountdown: osdType === "screenshot"

    readonly property string osdIcon: {
        switch (osdType) {
        case "volume":
            if (osdMuted)
                return "volume-x";
            if (osdValue > 0.66)
                return "volume-2";
            if (osdValue > 0.33)
                return "volume-1";
            return "volume";
        case "mic":
            return osdMuted ? "mic-off" : "mic";
        case "brightness":
            return osdValue > 0.33 ? "sun" : "sun-dim";
        case "media":
            return osdMuted ? "pause" : "play";
        case "battery":
            if (osdMuted)
                return "battery-charging";
            if (osdValue > 0.8)
                return "battery-full";
            if (osdValue > 0.2)
                return "battery-medium";
            return "battery-low";
        case "keyboard":
            return "keyboard";
        case "screenshot":
            return "camera";
        default:
            return "activity";
        }
    }

    // ── Window setup ──────────────────────────────────────────────────────
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    focusable: false
    visible: true

    mask: Region {
        item: osd.shown ? card : null
    }

    implicitWidth: 300
    implicitHeight: card.implicitHeight + 40

    anchors {
        bottom: true
        right: true
    }
    margins.bottom: Theme.barHeight + 16

    // ── Show / hide animation ────────────────────────────────────────────
    property bool shown: false

    property real riseOffset: shown ? 0 : 24

    Behavior on riseOffset {
        NumberAnimation {
            duration: shown ? 260 : 200
            easing.type: shown ? Easing.OutCubic : Easing.InCubic
        }
    }

    // ── Public API ────────────────────────────────────────────────────────
    function show(type, title, value, muted, subtitle) {
        osdType = type;
        osdTitle = title;
        osdValue = value;
        osdMuted = muted;
        osdSubtitle = subtitle ?? "";
        shown = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1800
        onTriggered: osd.shown = false
    }

    // ── Service watchers ──────────────────────────────────────────────────
    Connections {
        target: AudioService
        function onVolumeChanged() {
            osd.show("volume", "Volume", AudioService.volume, AudioService.muted);
        }
        function onMutedChanged() {
            osd.show("volume", "Volume", AudioService.volume, AudioService.muted);
        }
        function onSourceVolumeChanged() {
            osd.show("mic", "Microphone", AudioService.sourceVolume, AudioService.sourceMuted);
        }
        function onSourceMutedChanged() {
            osd.show("mic", "Microphone", AudioService.sourceVolume, AudioService.sourceMuted);
        }
    }

    Connections {
        target: BrightnessService
        function onPercentageChanged() {
            if (BrightnessService.isAvailable)
                osd.show("brightness", "Brightness", BrightnessService.percentage, false);
        }
    }

    Connections {
        target: MediaService
        function onIsPlayingChanged() {
            osd.show("media", MediaService.title, 0.0, !MediaService.isPlaying, MediaService.artist);
        }
        function onTitleChanged() {
            if (MediaService.hasPlayer)
                osd.show("media", MediaService.title, 0.0, !MediaService.isPlaying, MediaService.artist);
        }
    }

    Connections {
        target: BatteryService
        function onIsChargingChanged() {
            if (!BatteryService.hasBattery)
                return;
            osd.show("battery", BatteryService.isCharging ? "Charging" : "Battery", BatteryService.percentage / 100.0, BatteryService.isCharging);
        }
    }

    Connections {
        target: KeyboardService
        function onCurrentLayoutChanged() {
            osd.show("keyboard", "Keyboard Layout", 0.0, false, KeyboardService.getFull(KeyboardService.currentLayout));
        }
    }

    // Screenshot countdown — needed since the QuickActions drawer closes
    // immediately after picking delay2/delay5, so this OSD is the only
    // visible feedback the user gets while grim waits to fire.
    Connections {
        target: ScreenshotService
        function onCountdownTick(remaining) {
            hideTimer.interval = 900;
            if (remaining > 0)
                osd.show("screenshot", "Screenshot in", remaining, false, "Hold still...");
            else
                hideTimer.interval = 1800;
        }
    }

    // ── Content ───────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent

        implicitWidth: 260
        implicitHeight: contentColumn.implicitHeight + 32

        radius: Theme.radius
        color: Theme.background
        border.color: Theme.borderColor
        border.width: Theme.widgetBorderWidth

        opacity: osd.shown ? 1.0 : 0.0
        scale: osd.shown ? 1.0 : 0.94
        y: osd.riseOffset

        Behavior on opacity {
            NumberAnimation {
                duration: osd.shown ? 220 : 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: osd.shown ? 260 : 180
                easing.type: Easing.OutCubic
            }
        }

        // Subtle top highlight — signature detail, not a full shadow system
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 1
            }
            height: 1
            radius: 1
            color: Theme.foreground
            opacity: 0.06
        }

        RowLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 14

            // ── Icon badge (or countdown number) ──────────────────────────
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 42
                height: 42
                radius: width / 2
                color: Theme.backgroundAlt
                border.color: Theme.borderColor
                border.width: Theme.widgetBorderWidth

                Behavior on width {
                    NumberAnimation {
                        duration: 150
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 150
                    }
                }

                LucideIcon {
                    anchors.centerIn: parent
                    icon: osd.osdIcon
                    size: 20
                    color: osd.osdMuted ? Theme.foreground : Theme.selected
                    opacity: osd.osdMuted ? 0.5 : 1.0
                    visible: !osd.showCountdown
                }

                // Big countdown digit — replaces the icon for screenshot delay
                Text {
                    anchors.centerIn: parent
                    visible: osd.showCountdown
                    text: Math.round(osd.osdValue)
                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: 26
                    font.bold: true
                }
            }

            // ── Title + bar / subtitle ─────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: osd.osdTitle
                        elide: Text.ElideRight
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.foreground
                    }

                    Text {
                        visible: osd.showBar
                        text: Math.round(osd.osdValue * 100) + "%"
                        font.family: Theme.fontName
                        font.pixelSize: 12
                        opacity: 0.6
                        color: Theme.foreground
                    }
                }

                // Progress bar — volume / mic / brightness / battery
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    visible: osd.showBar

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Theme.foreground
                        opacity: 0.12
                    }

                    Rectangle {
                        id: barFill
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        radius: height / 2
                        color: osd.osdMuted ? Theme.foreground : Theme.selected
                        opacity: osd.osdMuted ? 0.35 : 1.0
                        width: Math.max(height, parent.width * (osd.osdMuted ? 0.0 : osd.osdValue))

                        Behavior on width {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }

                        Rectangle {
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }
                            height: parent.height / 2
                            radius: parent.radius
                            color: Theme.foreground
                            opacity: 0.12
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: !osd.showBar && osd.osdSubtitle !== ""
                    text: osd.osdSubtitle
                    elide: Text.ElideRight
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    opacity: 0.65
                    color: Theme.foreground
                }
            }
        }
    }
}
