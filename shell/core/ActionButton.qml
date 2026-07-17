import QtQuick
import qs.core

// Full-width action button — outline/ghost by default (border + text in
// baseColor, transparent-ish background), inverts to a solid filled
// button on hover (background becomes baseColor, text becomes contrast).
// Usage:
//   ActionButton {
//       Layout.fillWidth: true
//       label: device.connected ? "Disconnect" : "Connect"
//       baseColor: device.connected ? Theme.color1 : Theme.selected
//       onTapped: device.connected ? device.disconnect() : device.connect()
//   }
Rectangle {
    id: root

    property string label: ""
    property color baseColor: Theme.selected

    readonly property bool isHovered: hover.hovered

    height: 40
    radius: Theme.radius
    color: isHovered ? baseColor : "transparent"
    border.width: 1
    border.color: baseColor

    signal tapped

    Behavior on color {
        AnimColor {
            type: Anim.FastEffects
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.isHovered ? Theme.background : root.baseColor
        font.family: Theme.fontName
        font.pixelSize: 14
        font.bold: true
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        onTapped: root.tapped()
    }
}
