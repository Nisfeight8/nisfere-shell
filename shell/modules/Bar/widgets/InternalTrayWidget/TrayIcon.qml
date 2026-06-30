import QtQuick
import QtQuick.Controls
import qs.core

Item {
    id: root
    property string iconName: ""
    property string infoText: ""
    property string tooltipText: ""
    property int iconSize: 16
    implicitWidth: contentRow.implicitWidth
    implicitHeight: contentRow.implicitHeight
    Row {
        id: contentRow
        spacing: 6
        anchors.centerIn: parent

        LucideIcon {
            icon: root.iconName
            size: root.iconSize
            color: Theme.foreground
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.infoText !== ""
            text: root.infoText
            font.family: Theme.fontName
            font.pixelSize: 14
            color: Theme.foreground
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    CompactPopup {
        showPopup: hoverHandler.hovered && root.tooltipText !== ""
        targetItem: root

        contentComponent: Component {
            Text {
                text: root.tooltipText
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 11
                font.bold: true
                padding: 15
            }
        }
    }
}
