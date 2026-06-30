import QtQuick
import Quickshell
import qs.core
import qs.services

PopupWindow {
    id: root

    default property Component contentComponent
    required property bool showPopup
    required property Item targetItem
    property real targetX: targetItem.mapToItem(null, 0, 0).x + (targetItem.width / 2) - (root.width / 2)

    anchor.rect.x: Math.max(10, targetX)
    anchor.rect.y: Theme.barHeight
    anchor.window: myBar
    color: "transparent"
    implicitHeight: container.implicitHeight
    implicitWidth: container.implicitWidth
    visible: showPopup || container.opacity > 0


    PopupContainer {
        id: container

        bottomPadding: 15
        leftPadding: 30
        opacity: root.showPopup ? 1 : 0
        rightPadding: 30
        topPadding: 15
        y: root.showPopup ? 0 : -10

        Loader {
            id: contentLoader

            active: root.showPopup
            sourceComponent: root.contentComponent
        }
    }
}
