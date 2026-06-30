import QtQuick
import QtQuick.Controls
import qs.core

Slider {
    id: control

    property color progressColor: Theme.selected
    property color trackColor: Theme.backgroundAlt

    from: 0
    hoverEnabled: true
    to: 1

    background: Rectangle {
        color: control.trackColor
        height: implicitHeight
        implicitHeight: 8
        implicitWidth: 150
        radius: 4
        width: control.availableWidth
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2

        Rectangle {
            color: control.progressColor
            height: parent.height
            radius: 4
            width: control.visualPosition * parent.width
        }
    }
    handle: Rectangle {
        border.color: Theme.background
        border.width: 2
        color: control.pressed || control.hovered ? Theme.foreground : Theme.selected
        implicitHeight: 16
        implicitWidth: 16
        radius: 8
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }
}
