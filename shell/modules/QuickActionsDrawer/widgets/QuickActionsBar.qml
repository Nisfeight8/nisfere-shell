import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// Row of quick action buttons — knows about recording/screenshot state
// (that's its job), but delegates all button presentation to
// CircularActionButton from core.
Item {
    id: root

    signal actionRequested(string action)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

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

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 14

        Repeater {
            model: root._buttons

            CircularActionButton {
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
                    // Recording in progress — stop directly, don't open the panel
                    if (_isRecording) {
                        ScreenRecordService.stop();
                        return;
                    }
                    // Screenshot countdown running — tap cancels it
                    if (_isCountdown) {
                        ScreenshotService.cancel();
                        return;
                    }
                    root.actionRequested(modelData.action);
                }
            }
        }
    }
}
