import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    property string label: ""
    property string valueText: ""
    property string subText: ""
    property real usage: 0
    property color barColor: Theme.color2

    Layout.fillWidth: true
    spacing: 8

    Text {
        text: label
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 11
        font.bold: true
        opacity: 0.5
        width: 32
    }

    Rectangle {
        Layout.fillWidth: true
        height: 5
        radius: 3
        color: Theme.backgroundAlt

        Rectangle {
            width: parent.width * usage
            height: parent.height
            radius: parent.radius
            color: barColor
            Behavior on width {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 400
                }
            }
        }
    }

    Text {
        text: valueText
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 11
        width: 52
        horizontalAlignment: Text.AlignRight
    }

    Text {
        text: subText
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 11
        opacity: 0.45
        width: 40
    }
}
