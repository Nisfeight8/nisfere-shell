import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root

    property string activeIcon: "󰃠"
    property bool isMuteable: false
    property bool isMuted: false
    property string mutedIcon: "󰝟"
    property real value: 0.0

    signal toggleMuteClicked
    signal valueMoved(real newValue)

    Layout.fillWidth: true
    spacing: 12

    Rectangle {
        border.color: (root.isMuteable && root.isMuted) ? Theme.borderColor : "transparent"
        color: (root.isMuteable && root.isMuted) ? Theme.backgroundAlt : "transparent"
        height: 36
        radius: 18
        width: 36

        Text {
            anchors.centerIn: parent
            color: (root.isMuteable && root.isMuted) ? Theme.foreground : Theme.selected
            font.pixelSize: 18
            opacity: (root.isMuteable && root.isMuted) ? 0.5 : 1.0
            text: root.isMuted ? root.mutedIcon : root.activeIcon
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: root.isMuteable

            onClicked: root.toggleMuteClicked()
        }
    }
    ControlSlider {
        id: internalSlider

        Layout.fillWidth: true
        isMuted: root.isMuteable && root.isMuted
        value: root.value

        onMoved: root.valueMoved(internalSlider.value)
    }
    Text {
        Layout.preferredWidth: 35
        color: Theme.foreground
        font.pixelSize: 12
        horizontalAlignment: Text.AlignRight
        opacity: 0.7
        text: (root.isMuteable && root.isMuted) ? "Mute" : Math.round(internalSlider.value * 100) + "%"
    }
}
