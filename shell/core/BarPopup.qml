import QtQuick
import Quickshell
import qs.core

// anchor.window uses targetItem's QsWindow.window (Quickshell's OWN
// attached property) instead of a hardcoded window id — see
// BarTooltip.qml for the full rationale.
//
// Animation now follows the same offset-driven pattern as
// BaseDrawer/AnimatedContentLoader (see core/anim/OpenCloseOffset.qml)
// instead of relying on PopupContainer's own internal Behaviors:
// opacity/y are derived directly from `motion.offset`, which is
// already smoothly animated, so no extra Behavior is wanted on top of
// it (see PopupContainer's `selfAnimated` — turned off here for that
// reason; BarTooltip is untouched and still uses PopupContainer's own
// Behaviors as before).
PopupWindow {
    id: root

    default property Component contentComponent
    required property bool showPopup
    required property Item targetItem
    property real targetX: targetItem.mapToItem(null, 0, 0).x + (targetItem.width / 2) - (root.width / 2)

    anchor.rect.x: Math.max(10, targetX)
    anchor.rect.y: Theme.barHeight
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

        opacity: 1.0 - motion.offset
        y: -10 * motion.offset

        // Same keep-alive-during-close-animation logic as
        // DrawerContentHost/AnimatedContentLoader — see
        // DelayedUnloadLoader.qml. unloadDelay is explicitly matched to
        // motion's own animation duration (+ a small buffer) — the
        // DelayedUnloadLoader's own generic 300ms default was shorter
        // than motion's 500ms DefaultSpatial curve, so content was
        // being destroyed ~200ms BEFORE the fade-out visually finished,
        // producing a jarring "content pops out mid-fade" glitch.
        DelayedUnloadLoader {
            id: contentLoader
            shown: root.showPopup
            unloadDelay: AnimTokens.durationDefaultSpatial + 50
            sourceComponent: root.contentComponent
        }
    }
}
