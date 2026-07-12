import QtQuick
import Quickshell
import qs.core
import qs.services
import "Drawer"

PanelWindow {
    id: root

    // ── Public API — unchanged from the original BaseDrawer ────────
    property int edge: Qt.LeftEdge
    property bool cornerMode: false
    property int cornerSecondaryEdge: Qt.TopEdge
    property real edgeMargin: Theme.panelBorderSize

    property real minPanelWidth: 0
    property real minPanelHeight: 0
    property real maxPanelWidth: -1
    property real maxPanelHeight: -1

    property real screenOffset: 0
    property bool toggleOnHover: true
    property bool asynchronousLoad: true
    property Component contentComponent

    property bool opened: false

    signal openRequest
    signal closeRequest
    signal toggleRequest

    readonly property bool isHorizontal: geometry.isHorizontal
    readonly property real panelWidth: geometry.panelWidth
    readonly property real panelHeight: geometry.panelHeight

    // ── Open/close animation drives geometry.offset ─────────────────
    property real offset: 1

    onOpenedChanged: {
        if (opened) {
            closeOffsetAnim.stop();
            openOffsetAnim.start();
        } else {
            openOffsetAnim.stop();
            closeOffsetAnim.start();
        }
    }

    Anim {
        id: openOffsetAnim
        target: root
        property: "offset"
        to: 0
        type: Anim.DefaultSpatial
    }
    Anim {
        id: closeOffsetAnim
        target: root
        property: "offset"
        to: 1
        type: Anim.DefaultSpatial
    }

    // ── Geometry ─────────────────────────────────────────────────────
    DrawerGeometry {
        id: geometry
        edge: root.edge
        cornerMode: root.cornerMode
        cornerSecondaryEdge: root.cornerSecondaryEdge
        edgeMargin: root.edgeMargin

        minPanelWidth: root.minPanelWidth
        minPanelHeight: root.minPanelHeight
        maxPanelWidth: root.maxPanelWidth
        maxPanelHeight: root.maxPanelHeight

        contentWidth: contentHost.contentImplicitWidth
        contentHeight: contentHost.contentImplicitHeight

        offset: root.offset
        screenOffset: root.screenOffset
    }

    // ── Window setup ──────────────────────────────────────────────────
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: root.opened
    visible: true

    implicitWidth: geometry.windowWidth
    implicitHeight: geometry.windowHeight

    // Smooths the actual Wayland surface resize request (this is what
    // the compositor sees). Without this, implicitWidth/Height jump
    // instantly on tab switches with different content sizes, and the
    // compositor's resize round-trip lag becomes visible as a brief gap
    // between the panel and the screen edge. The internal panelItem
    // stays instant (see below) — only the outer window geometry here
    // is eased, so content itself never visibly drifts, only reveals/
    // retracts smoothly as the window's clip region grows/shrinks.
    // Behavior on implicitWidth {
    //     Anim {
    //         type: Anim.DefaultSpatial
    //     }
    // }
    // Behavior on implicitHeight {
    //     Anim {
    //         type: Anim.DefaultSpatial
    //     }
    // }

    anchors {
        top: geometry.anchorTop
        bottom: geometry.anchorBottom
        left: geometry.anchorLeft
        right: geometry.anchorRight
    }
    margins {
        top: geometry.marginTop
        bottom: geometry.marginBottom
        left: geometry.marginLeft
        right: geometry.marginRight
    }

    // ── Hover-to-open/close ────────────────────────────────────────────
    // Direct child of the PanelWindow root — matches the original
    // BaseDrawer hierarchy exactly, avoiding the extra Item-wrapper
    // layer that caused cursor-shape-change hover flicker.
    DrawerHoverEdge {
        enabled: root.toggleOnHover
        onOpenRequested: root.openRequest()
        onCloseRequested: root.closeRequest()
    }

    // ── Panel body: background shape + hosted content ──────────────────
    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: panelItem
            height: root.isHorizontal ? parent.height : root.panelHeight
            width: root.isHorizontal ? root.panelWidth : parent.width

            // NOTE: intentionally NO Behavior on height/width here.
            // The slide open/close animation is driven entirely by
            // `offset` → margins (see DrawerGeometry), not by resizing
            // this Item. If content-driven size changes (e.g. switching
            // tabs inside a drawer) were animated here too, the container
            // and the AnimLoader's fade would run on independent timelines,
            // causing centered content to visibly drift sideways/vertically
            // while the container was mid-resize. Keeping this instant means
            // any resize happens in a single frame — invisible in practice
            // since it's paired with the content fade in the AnimLoader used
            // inside contentComponent (see the "resize while invisible"
            // pattern in AnimLoader.qml).

            // Position computed directly from geometry's INSTANT target
            // values (geometry.windowWidth/windowHeight) — NOT from
            // parent.width/height, which now tracks the ANIMATING outer
            // window size (see the Behavior on implicitWidth/Height above).
            // Using parent.* here would make panelItem's position
            // recalculate every frame as the window animates, while its
            // size stays instant — causing visible drift/flicker in the
            // shrink direction especially. Binding to geometry's stable
            // instant values means panelItem's position AND size both
            // settle in the same frame; only the outer window's clip
            // region grows/shrinks around it, giving a clean reveal
            // with zero internal motion.
            x: {
                if (geometry.anchorLeft)
                    return root.isHorizontal ? root.edgeMargin : 0;
                if (geometry.anchorRight)
                    return geometry.windowWidth - width - (root.isHorizontal ? root.edgeMargin : 0);
                return 0;
            }
            y: {
                if (geometry.anchorTop)
                    return root.isHorizontal ? 0 : root.edgeMargin;
                if (geometry.anchorBottom)
                    return geometry.windowHeight - height - (root.isHorizontal ? 0 : root.edgeMargin);
                return 0;
            }

            DrawerBackground {
                anchors.fill: parent
                edge: root.edge
                cornerMode: root.cornerMode
                opened: root.opened
                bgColor: Theme.background
            }

            DrawerContentHost {
                id: contentHost
                anchors.fill: parent
                contentComponent: root.contentComponent
                opened: root.opened
                asynchronousLoad: root.asynchronousLoad

                marginTop: geometry._mTop
                marginBottom: geometry._mBottom
                marginLeft: geometry._mLeft
                marginRight: geometry._mRight
            }
        }
    }
}
