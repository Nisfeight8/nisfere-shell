import QtQuick
import Quickshell
import qs.core

PopupWindow {
    id: root

    default property Component contentComponent
    required property bool showPopup
    required property Item targetItem

    // Υπολογισμός κεντραρίσματος
    property real targetX: targetItem.mapToItem(null, 0, 0).x + (targetItem.width / 2) - (implicitWidth / 2)

    anchor.rect.x: Math.max(10, targetX)
    anchor.rect.y: Theme.barHeight
    anchor.window: myBar

    color: "transparent"

    // Το μέγεθος του παραθύρου εξαρτάται από το περιεχόμενο του Loader + padding
    implicitWidth: contentLoader.implicitWidth + 20
    implicitHeight: contentLoader.implicitHeight + 20

    visible: showPopup || container.opacity > 0

    Item {
        id: container
        anchors.fill: parent

        // color: "transparent"
        // // border.color: Theme.borderColor
        // // border.width: 1
        // radius: 6

        PanelShape {
            anchors.fill: parent
            edge: Qt.TopEdge
            invRadius: Theme.radius
            normalRadius: Theme.radius
        }

        opacity: root.showPopup ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        Loader {
            id: contentLoader
            anchors.centerIn: parent
            active: root.showPopup
            sourceComponent: root.contentComponent
        }
    }
}
