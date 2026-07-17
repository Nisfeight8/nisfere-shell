import QtQuick
import QtQuick.Layouts
import qs.core

// Label + value row for info cards (Status, Interface, MAC Address, ...).
// Usage:
//   InfoRow { label: "Status"; value: "Connected"; valueColor: Theme.selected }
RowLayout {
    id: root

    property string label: ""
    property string value: ""
    property color  valueColor: Theme.foreground
    property bool   valueBold: true

    Layout.fillWidth: true

    Text {
        Layout.fillWidth: true
        text: root.label
        color: Theme.foreground
        opacity: 0.7
        font.family: Theme.fontName
        font.pixelSize: 13
    }
    Text {
        text: root.value
        color: root.valueColor
        font.family: Theme.fontName
        font.pixelSize: 13
        font.bold: root.valueBold
    }
}
