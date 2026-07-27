import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

FocusScope {
    id: root
    // Was missing — content (below) correctly computes its own
    // implicit size from whichever row is visible, but root itself
    // never forwarded that upward, so this panel's real size never
    // reached the drawer's geometry chain.
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

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

    // Same keyboard navigation as QuickActionsBar/ScreenshotPanel —
    // Left/Right cycle the mode options (only meaningful while not
    // recording — while recording there's just the one Stop action),
    // Enter/Return/Space activates.
    property int currentIndex: 0
    property bool keyboardNavActive: false

    focus: true
    Component.onCompleted: forceActiveFocus()

    Keys.onLeftPressed: {
        keyboardNavActive = true;
        if (!ScreenRecordService.isRecording)
            currentIndex = (currentIndex - 1 + _options.length) % _options.length;
    }
    Keys.onRightPressed: {
        keyboardNavActive = true;
        if (!ScreenRecordService.isRecording)
            currentIndex = (currentIndex + 1) % _options.length;
    }
    Keys.onReturnPressed: _triggerCurrent()
    Keys.onEnterPressed: _triggerCurrent()
    Keys.onSpacePressed: _triggerCurrent()

    function _triggerCurrent() {
        if (ScreenRecordService.isRecording) {
            // Same reasoning as the Stop button's own onTapped below —
            // stop and navigate back to the bar in a single state
            // change, no simultaneous drawer close.
            ScreenRecordService.stop();
            ShellState.quickAction = "";
            return;
        }
        const modelData = _options[currentIndex];
        // NOTE: only close the drawer — do NOT also reset
        // ShellState.quickAction here. Resetting it now would swap
        // content back to the bar's smaller size at the exact instant
        // the close-slide animation starts, causing a visible
        // size-snap. The bar reset happens on next open instead (see
        // QuickActions's onOpenRequest).
        ShellState.quickActionsOpened = false;
        ScreenRecordService.start(modelData.mode);
    }

    Item {
        id: content
        anchors.fill: parent
        // Was `implicitWidth: optionsRow.implicitWidth` /
        // `implicitHeight: parent.implicitHeight` — the height half
        // referenced root's OWN implicit size (which nothing set, so
        // always 0), and neither dimension ever accounted for the
        // RECORDING state, where a differently-sized row is the one
        // actually visible. Now reflects whichever row is currently
        // shown.
        implicitWidth: ScreenRecordService.isRecording ? recordingRow.implicitWidth : optionsRow.implicitWidth
        implicitHeight: ScreenRecordService.isRecording ? recordingRow.implicitHeight : optionsRow.implicitHeight

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
                    // Keyboard-selected option reuses the same hover
                    // visuals — see CircularActionButton.forceHover.
                    forceHover: root.keyboardNavActive && root.currentIndex === index

                    onTapped: {
                        root.keyboardNavActive = false;
                        root.currentIndex = index;
                        root._triggerCurrent();
                    }
                }
            }
        }

        // ── Recording indicator (shown while recording) ───────────
        RowLayout {
            id: recordingRow
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
                // Only one action while recording — no left/right
                // needed, just highlight it once the user starts
                // navigating by keyboard at all.
                forceHover: root.keyboardNavActive

                onTapped: {
                    root.keyboardNavActive = false;
                    root._triggerCurrent();
                }
            }
        }
    }
}
