import QtQuick

// Hover-activated open/close behavior.
// IMPORTANT: this component's root type is HoverHandler itself (not an
// Item wrapping one) — see earlier fix for why (avoids cursor-shape-
// change hover flicker by matching the original direct-child hierarchy).
HoverHandler {
    id: root

    property int closeDelay: 300

    // Briefly ignore hover-loss right after a resize. Growing/shrinking
    // the window can cause a transient, spurious "unhovered" event while
    // the compositor catches up to the new surface bounds — without this,
    // a resize that happens to coincide with the tiniest cursor movement
    // can arm the close timer and close the drawer entirely by mistake.
    property bool suppressClose: false

    signal openRequested
    signal closeRequested

    onHoveredChanged: {
        if (hovered) {
            root.openRequested();
            closeTimer.stop();   // cancel any pending close — we're back
        } else if (!suppressClose) {
            closeTimer.start();
        }
    }

    property Timer closeTimer: Timer {
        interval: root.closeDelay
        onTriggered: {
            if (!root.hovered)
                root.closeRequested();
        }
    }
}
