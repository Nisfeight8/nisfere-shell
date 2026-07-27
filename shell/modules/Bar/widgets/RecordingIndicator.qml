import QtQuick
import qs.core
import qs.services

BarWidget {
    id: root

    visible: ScreenRecordService.isRecording
    bgColor: hover.hovered ? Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.12) : "transparent"
    spacing: 6

    Behavior on bgColor {
        AnimColor {
            type: Anim.FastEffects
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 8
        radius: 4
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

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: ScreenRecordService.formatDuration()
        color: Theme.color1
        font.family: Theme.fontName
        font.pixelSize: 13
        font.bold: true
    }

    // Was missing `parent: root` — same fix as InternalTrayWidget:
    // without it, these fall into contentRow.data and only cover the
    // tight dot+text area, not the full padded pill (paddingX: 12
    // default), missing clicks near the pill's edges.
    HoverHandler {
        id: hover
        parent: root
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        parent: root
        onTapped: ScreenRecordService.stop()
    }

    BarTooltip {
        showPopup: hover.hovered
        targetItem: root
        text: "Recording — click to stop"
    }
}
