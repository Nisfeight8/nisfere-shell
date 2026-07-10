import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.services

PanelWindow {
    id: root

    // ── Public API ────────────────────────────────────────────────────────────

    property Component contentComponent
    property bool asynchronousLoad: false   // false = size known before slide-in

    property int edge: Qt.LeftEdge
    property int edgeMargin: Theme.panelBorderSize
    property bool opened: false
    property int screenOffset: 0
    property bool toggleOnHover: true
    property bool cornerMode: false
    property int cornerSecondaryEdge: Qt.TopEdge

    property real minPanelWidth: 0
    property real minPanelHeight: 0
    property real maxPanelWidth: -1
    property real maxPanelHeight: -1

    readonly property Item loadedItem: contentLoader.item
    readonly property real nonAnimPanelWidth: _panelW
    readonly property real nonAnimPanelHeight: _panelH

    signal closeRequest
    signal openRequest
    signal toggleRequest

    // ── Internal geometry ─────────────────────────────────────────────────────

    readonly property bool _isH: edge === Qt.LeftEdge || edge === Qt.RightEdge

    readonly property real _mTop: (edge === Qt.TopEdge || (cornerMode && cornerSecondaryEdge === Qt.TopEdge)) ? 10 : 30
    readonly property real _mBottom: (edge === Qt.BottomEdge || (cornerMode && cornerSecondaryEdge === Qt.BottomEdge)) ? 0 : 30
    readonly property real _mLeft: (edge === Qt.LeftEdge || (cornerMode && cornerSecondaryEdge === Qt.LeftEdge)) ? 0 : 30
    readonly property real _mRight: (edge === Qt.RightEdge || (cornerMode && cornerSecondaryEdge === Qt.RightEdge)) ? 0 : 30

    property real _lastW: 0
    property real _lastH: 0

    // Surface size tracks content — always instant, never animated.
    // Animating the compositor surface buffer every frame causes the flicker.
    // If you want animated size changes, put Behavior on implicitWidth/Height
    // inside your contentComponent (gated by `opened`), not here.
    readonly property real _panelW: {
        const w = Math.max(minPanelWidth, _lastW + _mLeft + _mRight);
        return maxPanelWidth > 0 ? Math.min(w, maxPanelWidth) : w;
    }
    readonly property real _panelH: {
        const h = Math.max(minPanelHeight, _lastH + _mTop + _mBottom);
        return maxPanelHeight > 0 ? Math.min(h, maxPanelHeight) : h;
    }

    // The only animated property. One animation, no per-frame compositor resize.
    property real _slide: 1

    // ── PanelWindow config ────────────────────────────────────────────────────

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: root.opened
    visible: true

    implicitWidth: _panelW + (_isH ? edgeMargin : 0)
    implicitHeight: _panelH + (_isH ? 0 : edgeMargin)

    anchors {
        top: edge === Qt.TopEdge
        bottom: edge === Qt.BottomEdge
        left: edge === Qt.LeftEdge
        right: edge === Qt.RightEdge
    }

    // Lerp between two states (Caelestia pattern):
    //   _slide=0 → margin = screenOffset              (panel visible)
    //   _slide=1 → margin = -(panelSize + edgeMargin) (panel fully off-screen)
    margins {
        top: edge === Qt.TopEdge ? screenOffset - (screenOffset + _panelH + edgeMargin) * _slide : 0
        bottom: edge === Qt.BottomEdge ? screenOffset - (screenOffset + _panelH + edgeMargin) * _slide : 0
        left: edge === Qt.LeftEdge ? screenOffset - (screenOffset + _panelW + edgeMargin) * _slide : 0
        right: edge === Qt.RightEdge ? screenOffset - (screenOffset + _panelW + edgeMargin) * _slide : 0
    }

    // ── Open / close ──────────────────────────────────────────────────────────

    onOpenedChanged: {
        if (opened) {
            unloadTimer.stop();
            closeAnim.stop();
            openAnim.start();
        } else {
            openAnim.stop();
            closeAnim.start();
            unloadTimer.restart();
        }
    }

    NumberAnimation {
        id: openAnim
        target: root
        property: "_slide"
        to: 0
        duration: 300
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "_slide"
        to: 1
        duration: 250
        easing.type: Easing.InCubic
    }

    Timer {
        id: unloadTimer
        interval: 400
        onTriggered: gc()
    }

    // ── Size tracking ─────────────────────────────────────────────────────────

    function _sync() {
        // Freeze surface size during slide-out (Caelestia pattern).
        // While closing, content may still report new sizes (search results
        // updating, lazy widgets finishing) — we ignore them so the surface
        // stays stable and the slide animation is clean.
        if (closeAnim.running)
            return;
        const item = contentLoader.item;
        if (!item)
            return;
        if (item.implicitWidth > 0)
            _lastW = item.implicitWidth;
        if (item.implicitHeight > 0)
            _lastH = item.implicitHeight;
    }

    Connections {
        target: contentLoader.item
        function onImplicitWidthChanged() {
            root._sync();
        }
        function onImplicitHeightChanged() {
            root._sync();
        }
    }

    // ── Hover ─────────────────────────────────────────────────────────────────

    HoverHandler {
        id: hoverHandler
        enabled: root.toggleOnHover
        onHoveredChanged: hovered ? openRequest() : leaveTimer.start()
    }

    Timer {
        id: leaveTimer
        interval: 300
        onTriggered: if (!hoverHandler.hovered)
            closeRequest()
    }

    // ── Visual structure ──────────────────────────────────────────────────────

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: panelItem

            width: _isH ? root._panelW : parent.width
            height: _isH ? parent.height : root._panelH

            anchors {
                top: edge === Qt.TopEdge ? parent.top : undefined
                topMargin: edge === Qt.TopEdge ? (_isH ? 0 : edgeMargin) : 0
                bottom: edge === Qt.BottomEdge ? parent.bottom : undefined
                bottomMargin: edge === Qt.BottomEdge ? (_isH ? 0 : edgeMargin) : 0
                left: edge === Qt.LeftEdge ? parent.left : undefined
                leftMargin: edge === Qt.LeftEdge ? (_isH ? edgeMargin : 0) : 0
                right: edge === Qt.RightEdge ? parent.right : undefined
                rightMargin: edge === Qt.RightEdge ? (_isH ? edgeMargin : 0) : 0
            }

            Loader {
                anchors.fill: parent
                sourceComponent: root.cornerMode ? cornerShapeComp : panelShapeComp
            }

            WrapperItem {
                width: parent.width
                height: parent.height
                topMargin: root._mTop
                bottomMargin: root._mBottom
                leftMargin: root._mLeft
                rightMargin: root._mRight

                Loader {
                    id: contentLoader
                    active: root.opened || closeAnim.running || unloadTimer.running
                    asynchronous: root.asynchronousLoad
                    sourceComponent: root.contentComponent
                    onItemChanged: root._sync()
                }
            }

            Component {
                id: panelShapeComp
                PanelShape {
                    anchors.fill: parent
                    bgColor: Theme.background
                    edge: root.edge
                    borderColor: root.opened ? Theme.borderColor : "transparent"
                    Behavior on borderColor {
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.Linear
                        }
                    }
                }
            }

            Component {
                id: cornerShapeComp
                CornerShape {
                    anchors.fill: parent
                    bgColor: Theme.background
                    edge: root.edge
                    borderColor: root.opened ? Theme.borderColor : "transparent"
                    Behavior on borderColor {
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.Linear
                        }
                    }
                }
            }
        }
    }
}
