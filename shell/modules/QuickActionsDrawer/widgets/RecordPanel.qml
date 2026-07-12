import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

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
    ]

    Item {
        id: content
        anchors.fill: parent
        implicitWidth: optionsRow.implicitWidth
        implicitHeight: parent.implicitHeight

        // ── Options (shown when not recording) ────────────────────
        RowLayout {
            id: optionsRow
            anchors.centerIn: parent
            spacing: 14
            visible: !ScreenRecordService.isRecording

            Repeater {
                model: root._options

                CircularActionButton {
                    icon: modelData.icon
                    label: modelData.label

                    hoverColor: Theme.selected
                    activeColor: Theme.color1

                    onTapped: {
                        // NOTE: only close the drawer — do NOT also reset
                        // ShellState.quickAction here. Resetting it now
                        // would swap content back to the bar's smaller
                        // size at the exact instant the close-slide
                        // animation starts, causing a visible size-snap.
                        // The bar reset happens on next open instead
                        // (see QuickActionsDrawer's onOpenRequest).
                        ShellState.quickActionsOpened = false;
                        ScreenRecordService.start(modelData.mode);
                    }
                }
            }
        }

        // ── Recording indicator (shown while recording) ───────────
        RowLayout {
            anchors.centerIn: parent
            spacing: 18
            visible: ScreenRecordService.isRecording

            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: Theme.color1
                SequentialAnimation on opacity {
                    running: ScreenRecordService.isRecording
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.25
                        duration: 650
                    }
                    NumberAnimation {
                        to: 1.0
                        duration: 650
                    }
                }
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Recording..."
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    font.bold: true
                }
                Text {
                    text: ScreenRecordService.formatDuration()
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    opacity: 0.6
                }
            }

            CircularActionButton {
                icon: "square"
                label: "Stop"
                diameter: 52
                iconSize: 18

                isActive: true
                activeColor: Theme.color1
                hoverColor: Theme.selected
                showPulse: true
                pulseColor: Theme.selected

                onTapped: {
                    // Same reasoning as above — stop the recording and
                    // navigate back to the bar in a SINGLE state change
                    // (quickAction reset only), no simultaneous drawer
                    // close, so there's nothing to race against here.
                    ScreenRecordService.stop();
                    ShellState.quickAction = "";
                }
            }
        }
    }
}
