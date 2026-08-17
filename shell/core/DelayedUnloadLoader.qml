import QtQuick
import qs.services
// Drop-in replacement for a bare `Loader` that keeps the loaded item
// alive for `unloadDelay` ms after `shown` goes false — long enough
// for whatever close/fade animation the CALLER runs on its own
// opacity/position to actually show the content disappearing, instead
// of the content vanishing instantly while an empty container fades.
//
// Same pattern DrawerContentHost.qml already uses internally for
// drawers; extracted here so BarPopup/AnimatedContentLoader (and
// anything else with a show/hide fade over lazy-loaded content) don't
// have to re-derive it from scratch.
//
// Sizing follows the SAME two-channel split as DrawerContentHost:
//   - implicitWidth/implicitHeight report the loaded content's own
//     implicit size UPWARD, for a caller that wants to size itself
//     AROUND this (e.g. a WrapperItem computing margins).
//   - this component's own ACTUAL width/height are NEVER self-bound
//     to those — whoever contains it decides the actual size, exactly
//     like a bare Loader leaves that decision to its container
//     (anchors.fill: parent, or a WrapperItem/MarginWrapperManager
//     setting it directly). Binding actual size to the implicit
//     values here too was the earlier bug: it fought with an external
//     `anchors.fill: parent`, leaving the item pinned small in the
//     top-left corner instead of filling its region.
Item {
    id: root

    property Component sourceComponent
    // Named "shown", not "active" — avoids the confusing "active but
    // not shown" state during the post-close grace period; this is
    // the caller's open/visible intent, not the Loader's own active.
    property bool shown: false
    property bool asynchronousLoad: true
    property int unloadDelay: ShellState.drawerDelayInterval   // ms to keep content alive after close, for the close animation

    // When true: starts loading immediately (asynchronously — this
    // never blocks anything) as soon as THIS item exists, regardless
    // of `shown`, and once loaded, NEVER unloads again (unloadDelay/
    // gc() no longer apply). For content that's cheap to keep around
    // and gets shown via a fade animation (a bar popup's menu/
    // tooltip, say) — trades a small amount of persistent memory for
    // eliminating load-time stutter on EVERY open, including the very
    // first one. Was previously a choice between two bad options for
    // that first open specifically: asynchronousLoad: true raced the
    // open animation (content visibly popping in partway through, as
    // the Loader finished in the background while the fade was
    // already playing), asynchronousLoad: false avoided that race but
    // synchronously blocked the GUI thread right at the moment the
    // animation was supposed to start (a freeze instead of a pop-in).
    // Preloading well before the animation ever runs sidesteps the
    // tradeoff entirely — by the time you actually open it, there's
    // nothing left to load.
    property bool preload: false

    readonly property alias item: loader.item

    implicitWidth: loader.item?.implicitWidth ?? 0
    implicitHeight: loader.item?.implicitHeight ?? 0

    signal contentSizeChanged

    onShownChanged: {
        if (preload)
            return; // preloaded content stays loaded permanently — see below
        if (shown)
            unloadTimer.stop();
        else
            unloadTimer.restart();
    }

    Timer {
        id: unloadTimer
        interval: root.unloadDelay
        onTriggered: gc()
    }

    Loader {
        id: loader
        anchors.fill: parent
        // preload keeps this active unconditionally, from the moment
        // this item is created, regardless of shown/unloadTimer —
        // loads once, in the background, stays loaded forever after.
        active: root.preload || root.shown || unloadTimer.running
        asynchronous: root.asynchronousLoad
        sourceComponent: root.sourceComponent

        onItemChanged: root.contentSizeChanged()
    }

    Connections {
        target: loader.item
        function onImplicitWidthChanged() {
            root.contentSizeChanged();
        }
        function onImplicitHeightChanged() {
            root.contentSizeChanged();
        }
    }
}
