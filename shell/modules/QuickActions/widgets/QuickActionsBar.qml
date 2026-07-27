import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// Row of quick action buttons — knows about recording/screenshot state
// (that's its job), but delegates all button presentation to
// CircularActionButton from core.
FocusScope {
    id: root

    signal actionRequested(string action)

    // Keyboard navigation: Left/Right move between buttons, Enter/
    // Return/Space activates the highlighted one. FocusScope (not
    // plain Item) + forceActiveFocus below so Keys.onXxx here actually
    // receives events once this page is loaded — matches
    // AnimatedContentLoader's own FocusScope pattern elsewhere.
    property int currentIndex: 0
    property bool keyboardNavActive: false

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    focus: true
    Component.onCompleted: forceActiveFocus()

    Keys.onLeftPressed: {
        keyboardNavActive = true;
        currentIndex = (currentIndex - 1 + _buttons.length) % _buttons.length;
    }
    Keys.onRightPressed: {
        keyboardNavActive = true;
        currentIndex = (currentIndex + 1) % _buttons.length;
    }
    Keys.onReturnPressed: _triggerAction(currentIndex)
    Keys.onEnterPressed: _triggerAction(currentIndex)
    Keys.onSpacePressed: _triggerAction(currentIndex)

    readonly property var _buttons: [
        {
            icon: "image",
            label: "Wallpaper",
            action: "wallpaper"
        },
        {
            icon: "palette",
            label: "Colors",
            action: "colors"
        },
        {
            icon: "camera",
            label: "Screenshot",
            action: "screenshot"
        },
        {
            icon: "circle-dot",
            label: "Record",
            action: "recorder"
        },
        {
            icon: "pipette",
            label: "Picker",
            action: "colorpicker"
        },
        {
            icon: "clipboard-list",
            label: "Clipboard",
            action: "clipboard"
        },
    ]

    // Shared by both mouse taps and keyboard activation — single
    // source of truth for "what happens when you activate button N",
    // instead of duplicating the recording/countdown special-casing
    // in two separate places (was only in onTapped before).
    function _triggerAction(index) {
        const modelData = _buttons[index];
        const isRecordBtn = modelData.action === "recorder";
        const isShotBtn = modelData.action === "screenshot";
        const isRecording = isRecordBtn && ScreenRecordService.isRecording;
        const isCountdown = isShotBtn && ScreenshotService.isCapturing && ScreenshotService.countdown > 0;

        if (isRecording) {
            ScreenRecordService.stop();
            return;
        }
        if (isCountdown) {
            ScreenshotService.cancel();
            return;
        }
        root.actionRequested(modelData.action);
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 14

        Repeater {
            model: root._buttons

            CircularActionButton {
                id: btn
                readonly property bool _isRecordBtn: modelData.action === "recorder"
                readonly property bool _isShotBtn: modelData.action === "screenshot"
                readonly property bool _isRecording: _isRecordBtn && ScreenRecordService.isRecording
                readonly property bool _isCountdown: _isShotBtn && ScreenshotService.isCapturing && ScreenshotService.countdown > 0

                icon: _isRecording ? "square" : modelData.icon
                label: _isRecording ? ScreenRecordService.formatDuration() : _isCountdown ? ScreenshotService.countdown.toString() : modelData.label

                isActive: ShellState.quickAction === modelData.action || _isRecording || _isCountdown
                showPulse: _isRecording || _isCountdown
                pulseColor: _isRecording ? Theme.color1 : Theme.color3
                activeColor: _isRecording ? Theme.color1 : (_isCountdown ? Theme.color3 : Theme.color1)
                hoverColor: Theme.selected
                // Keyboard-selected button reuses the SAME hover
                // visuals instead of a separate focus-ring look —
                // simpler and more consistent than inventing new UI.
                forceHover: root.keyboardNavActive && root.currentIndex === index

                tooltipText: {
                    if (_isRecording)
                        return "Stop recording";
                    if (_isCountdown)
                        return "Capturing...";
                    switch (modelData.action) {
                    case "recorder":
                        return "Record screen";
                    case "colorpicker":
                        return "Pick a color";
                    default:
                        return modelData.label;
                    }
                }

                onTapped: {
                    root.keyboardNavActive = false;
                    root._triggerAction(index);
                }
            }
        }
    }
}
