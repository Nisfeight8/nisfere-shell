import QtQuick
import qs.core
import qs.services

// Two DIFFERENT visual modes, ONE shared content (OSDContent.qml):
//   - NOT fullscreen -> hosted via BaseDrawer (cornerMode bottom-right,
//     matching the other drawers)
//   - fullscreen -> hosted via a simple floating popup Item (no bar to
//     dock against, no reason to use drawer-style edge positioning)
//
// A Loader swaps between the two MODE WRAPPERS based on hasFullscreen —
// only ONE is ever instantiated at a time (never both simultaneously),
// so there's no duplicate loading; only the CONTENT (OSDContent) is
// shared/reused identically by whichever wrapper is currently active.
Item {
    id: root
    anchors.fill: parent

    property bool hasFullscreen: false

    // Exposed for ScreenBorder's mask — works regardless of which mode
    // is currently active, since BOTH mode components below expose a
    // property named `panelItem`.
    readonly property Item panelItem: modeLoader.item ? modeLoader.item.panelItem : null

    // ── OSD state (shared by both modes) ──────────────────────────────────
    property string osdType: "volume"
    property string osdTitle: "Volume"
    property string osdSubtitle: ""
    property real osdValue: 0.0
    property bool osdMuted: false

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
            // Was `osdMuted ? "pause" : "play"` — backwards relative
            // to the established convention (MiniMedia.qml/Media.qml:
            // `MediaService.isPlaying ? "pause" : "play"`). osdMuted
            // here means `!isPlaying`, so the condition needs
            // inverting to match: playing -> "pause" (the action
            // you'd take), paused -> "play".
            return osdMuted ? "play" : "pause";
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

    property bool shown: false

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
        onTriggered: root.shown = false
    }

    Connections {
        target: AudioService
        function onVolumeChanged() {
            root.show("volume", "Volume", AudioService.volume, AudioService.muted);
        }
        function onMutedChanged() {
            root.show("volume", "Volume", AudioService.volume, AudioService.muted);
        }
        function onSourceVolumeChanged() {
            root.show("mic", "Microphone", AudioService.sourceVolume, AudioService.sourceMuted);
        }
        function onSourceMutedChanged() {
            root.show("mic", "Microphone", AudioService.sourceVolume, AudioService.sourceMuted);
        }
    }
    Connections {
        target: BrightnessService
        function onPercentageChanged() {
            if (BrightnessService.isAvailable)
                root.show("brightness", "Brightness", BrightnessService.percentage, false);
        }
    }
    Connections {
        target: MediaService
        function onIsPlayingChanged() {
            root.show("media", MediaService.title, 0.0, !MediaService.isPlaying, MediaService.artist);
        }
        function onTitleChanged() {
            if (MediaService.hasPlayer)
                root.show("media", MediaService.title, 0.0, !MediaService.isPlaying, MediaService.artist);
        }
    }
    Connections {
        target: BatteryService
        function onIsChargingChanged() {
            if (!BatteryService.hasBattery)
                return;
            root.show("battery", BatteryService.isCharging ? "Charging" : "Battery", BatteryService.percentage / 100.0, BatteryService.isCharging);
        }
    }
    Connections {
        target: KeyboardService
        function onCurrentLayoutChanged() {
            root.show("keyboard", "Keyboard Layout", 0.0, false, KeyboardService.getFull(KeyboardService.currentLayout));
        }
    }
    Connections {
        target: ScreenshotService
        function onCountdownTick(remaining) {
            hideTimer.interval = 900;
            if (remaining > 0)
                root.show("screenshot", "Screenshot in", remaining, false, "Hold still...");
            else
                hideTimer.interval = 1800;
        }
    }

    // ── Mode switch — only ONE of these is ever instantiated ──────────────
    Loader {
        id: modeLoader
        anchors.fill: parent
        sourceComponent: root.hasFullscreen ? popupModeComp : drawerModeComp
    }

    // ── Mode 1: NOT fullscreen — BaseDrawer, cornerMode bottom-right ──────
    Component {
        id: drawerModeComp
        BaseDrawer {
            cornerMode: true
            edge: Qt.RightEdge
            cornerSecondaryEdge: Qt.BottomEdge
            toggleOnHover: false
            openedRequest: root.shown
            screenOffset: Theme.barHeight

            contentComponent: Component {
                OSDContent {
                    osdIconName: root.osdIcon
                    osdTitleText: root.osdTitle
                    osdSubtitleText: root.osdSubtitle
                    osdValueNum: root.osdValue
                    osdMutedFlag: root.osdMuted
                    showBarFlag: root.showBar
                    showCountdownFlag: root.showCountdown
                }
            }
        }
    }

    // ── Mode 2: fullscreen — simple floating popup, no drawer chrome ─────
    Component {
        id: popupModeComp
        Item {
            id: popupWrapper
            anchors.fill: parent
            readonly property alias panelItem: card

            Rectangle {
                id: card
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    bottomMargin: Theme.panelBorderSize + 20
                    rightMargin: Theme.panelBorderSize + 20
                }
                width: 260
                height: contentInner.implicitHeight
                radius: Theme.radius
                clip: true
                color: Theme.background
                border.color: Theme.borderColor
                border.width: Theme.widgetBorderWidth

                opacity: root.shown ? 1.0 : 0.0
                scale: root.shown ? 1.0 : 0.94
                transform: Translate {
                    y: root.shown ? 0 : 24
                }
                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }
                Behavior on scale {
                    Anim {
                        type: Anim.FastEffects
                    }
                }

                OSDContent {
                    id: contentInner
                    anchors.fill: parent
                    osdIconName: root.osdIcon
                    osdTitleText: root.osdTitle
                    osdSubtitleText: root.osdSubtitle
                    osdValueNum: root.osdValue
                    osdMutedFlag: root.osdMuted
                    showBarFlag: root.showBar
                    showCountdownFlag: root.showCountdown
                }
            }
        }
    }
}
