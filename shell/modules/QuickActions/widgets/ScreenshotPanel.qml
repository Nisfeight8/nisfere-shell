import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

FocusScope {
    id: root
    // Bottom-up from `row` (the button RowLayout) — the countdown
    // overlay below uses anchors.fill: parent, so it doesn't factor
    // into sizing, only `row`'s own content does.
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // Same keyboard navigation as QuickActionsBar.qml — Left/Right
    // move, Enter/Return/Space activates. FocusScope + forceActiveFocus
    // so Keys.onXxx here actually receives events once this page loads.
    property int currentIndex: 0
    property bool keyboardNavActive: false

    focus: true
    Component.onCompleted: forceActiveFocus()

    Keys.onLeftPressed: {
        keyboardNavActive = true;
        currentIndex = (currentIndex - 1 + _options.length) % _options.length;
    }
    Keys.onRightPressed: {
        keyboardNavActive = true;
        currentIndex = (currentIndex + 1) % _options.length;
    }
    Keys.onReturnPressed: _triggerOption(currentIndex)
    Keys.onEnterPressed: _triggerOption(currentIndex)
    Keys.onSpacePressed: _triggerOption(currentIndex)

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

    // Shared by both mouse taps and keyboard activation.
    function _triggerOption(index) {
        const modelData = _options[index];
        ShellState.quickAction = "";
        ShellState.quickActionsOpened = false;
        ScreenshotService.capture(modelData.mode);
    }

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

                // Keyboard-selected option reuses the same hover
                // visuals — see CircularActionButton.forceHover.
                forceHover: root.keyboardNavActive && root.currentIndex === index

                onTapped: {
                    root.keyboardNavActive = false;
                    root._triggerOption(index);
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
