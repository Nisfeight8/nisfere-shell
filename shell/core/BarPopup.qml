import QtQuick
import Quickshell
import qs.core

PopupWindow {
    id: root

    default property Component contentComponent
    required property bool showPopup
    required property Item targetItem
    property real targetX: targetItem.mapToItem(null, 0, 0).x + (targetItem.width / 2) - (root.width / 2)

    // Resolved once here, at the one place in this file that already
    // needs QsWindow.window?.screen (for scaledBarHeight) — passed
    // down to PopupContainer, which exposes it further to whatever
    // contentComponent is loaded inside, so popup content doesn't
    // need to re-derive this independently.
    readonly property real uiScale: Theme.scaleFor(QsWindow.window?.screen)

    anchor.rect.x: Math.max(10, targetX)
    anchor.rect.y: Theme.scaledBarHeight(QsWindow.window?.screen)
    anchor.window: targetItem.QsWindow.window
    color: "transparent"
    implicitHeight: container.implicitHeight
    implicitWidth: container.implicitWidth
    visible: motion.offset < 1

    OpenCloseOffset {
        id: motion
        opened: root.showPopup
    }

    PopupContainer {
        id: container
        selfAnimated: false
        uiScale: root.uiScale

        opacity: 1.0 - motion.offset
        y: -10 * motion.offset

        DelayedUnloadLoader {
            id: contentLoader
            shown: root.showPopup
            unloadDelay: AnimTokens.durationDefaultSpatial + 50
            sourceComponent: root.contentComponent
        }
    }
}
