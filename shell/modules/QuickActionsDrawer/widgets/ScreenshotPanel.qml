import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    // implicitWidth: row.implicitWidth + 32
    // implicitHeight: 110

    readonly property var _options: [
        {
            icon: "monitor",
            label: "Full screen",
            mode: "full"
        },
        {
            icon: "app-window",
            label: "Window",
            mode: "window"
        },
        {
            icon: "crop",
            label: "Area",
            mode: "area"
        },
        {
            icon: "timer",
            label: "2 seconds",
            mode: "delay2"
        },
        {
            icon: "timer",
            label: "5 seconds",
            mode: "delay5"
        },
    ]

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 14

        Repeater {
            model: root._options

            CircularActionButton {
                icon: modelData.icon
                label: modelData.label
                // diameter: 56
                // iconSize: 22

                onTapped: {
                    ShellState.quickAction = "";
                    ShellState.quickActionsOpened = false;
                    ScreenshotService.capture(modelData.mode);
                }
            }
        }
    }

    // ── Countdown overlay (delay2/delay5) ─────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.9)
        visible: ScreenshotService.isCapturing && ScreenshotService.countdown > 0

        Text {
            anchors.centerIn: parent
            text: ScreenshotService.countdown
            color: Theme.selected
            font.family: Theme.fontName
            font.pixelSize: 42
            font.bold: true
        }
    }
}
