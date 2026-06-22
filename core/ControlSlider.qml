import QtQuick
import QtQuick.Controls
import qs.core

Slider {
    id: control

    property bool isMuted: false

    property color progressColor: Theme.selected
    property color trackColor: Theme.background

    from: 0
    hoverEnabled: true
    implicitHeight: 32
    implicitWidth: 150
    to: 1

    background: Rectangle {
        color: control.trackColor
        height: 24
        radius: 12
        width: control.availableWidth
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2

        Rectangle {
            color: control.isMuted ? Theme.borderColor : control.progressColor
            height: parent.height
            radius: parent.radius
            width: control.visualPosition * parent.width
        }
    }
    handle: Rectangle {
        border.color: Theme.background
        border.width: 2
        color: control.pressed ? Theme.foreground : Theme.selected
        implicitHeight: 36
        implicitWidth: 16
        opacity: (control.hovered || control.pressed) ? 1.0 : 0.0
        radius: 9
        scale: (control.hovered || control.pressed) ? 1.0 : 0.5
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }
}
