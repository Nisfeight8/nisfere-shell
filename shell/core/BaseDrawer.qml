import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.services

PanelWindow {
    id: root

    property Component contentComponent
    readonly property int closeAnimationDuration: 500
    readonly property Item loadedItem: contentLoader.item

    property bool asynchronousLoad: true

    property int edge: Qt.LeftEdge
    property int edgeMargin: Theme.panelBorderSize
    property real offset: 1
    property bool opened: false
    property int screenOffset: 0
    property bool toggleOnHover: true
    property bool cornerMode: false
    property int cornerSecondaryEdge: Qt.TopEdge

    readonly property real _mTop: (edge === Qt.TopEdge || (cornerMode && cornerSecondaryEdge === Qt.TopEdge)) ? 10 : 30
    readonly property real _mBottom: (edge === Qt.BottomEdge || (cornerMode && cornerSecondaryEdge === Qt.BottomEdge)) ? 0 : 30
    readonly property real _mLeft: (edge === Qt.LeftEdge || (cornerMode && cornerSecondaryEdge === Qt.LeftEdge)) ? 0 : 30
    readonly property real _mRight: (edge === Qt.RightEdge || (cornerMode && cornerSecondaryEdge === Qt.RightEdge)) ? 0 : 30

    readonly property bool isHorizontal: edge === Qt.LeftEdge || edge === Qt.RightEdge

    property real minPanelWidth: 0
    property real minPanelHeight: 0

    property real _lastKnownWidth: 0
    property real _lastKnownHeight: 0

    property real maxPanelHeight: -1   // -1 = χωρίς όριο
    property real maxPanelWidth: -1

    property real panelHeight: {
        var h = Math.max(root.minPanelHeight, _lastKnownHeight + root._mTop + root._mBottom);
        return root.maxPanelHeight > 0 ? Math.min(h, root.maxPanelHeight) : h;
    }
    property real panelWidth: {
        var w = Math.max(root.minPanelWidth, _lastKnownWidth + root._mLeft + root._mRight);
        return root.maxPanelWidth > 0 ? Math.min(w, root.maxPanelWidth) : w;
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: root.opened

    implicitHeight: root.panelHeight + (isHorizontal ? 0 : root.edgeMargin)
    implicitWidth: root.panelWidth + (isHorizontal ? root.edgeMargin : 0)

    visible: true

    signal closeRequest
    signal openRequest
    signal toggleRequest

    function _syncPanelSize() {
        const item = contentLoader.item;
        if (!item)
            return;
        if (item.implicitWidth > 0)
            _lastKnownWidth = item.implicitWidth;
        if (item.implicitHeight > 0)
            _lastKnownHeight = item.implicitHeight;
    }

    Connections {
        target: contentLoader.item
        function onImplicitWidthChanged() {
            root._syncPanelSize();
        }
        function onImplicitHeightChanged() {
            root._syncPanelSize();
        }
    }

    Component.onCompleted: _syncPanelSize()

    onOpenedChanged: {
        if (opened) {
            closeOffsetAnim.stop();
            openOffsetAnim.start();
        } else {
            openOffsetAnim.stop();
            closeOffsetAnim.start();
            unloadDelayTimer.restart();
        }
    }

    // ── Animations ────────────────────────────────────────────────────────

    NumberAnimation {
        id: openOffsetAnim
        target: root
        property: "offset"
        to: 0
        duration: 300
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeOffsetAnim
        target: root
        property: "offset"
        to: 1
        duration: 250
        easing.type: Easing.InCubic
    }

    Timer {
        id: unloadDelayTimer
        interval: root.closeAnimationDuration
        onTriggered: gc()
    }

    anchors {
        bottom: edge === Qt.BottomEdge
        left: edge === Qt.LeftEdge
        right: edge === Qt.RightEdge
        top: edge === Qt.TopEdge
    }

    margins {
        bottom: edge === Qt.BottomEdge ? (screenOffset * (1 - offset)) - (panelHeight * offset) : 0
        left: edge === Qt.LeftEdge ? (screenOffset * (1 - offset)) - (panelWidth * offset) : 0
        right: edge === Qt.RightEdge ? (screenOffset * (1 - offset)) - (panelWidth * offset) : 0
        top: edge === Qt.TopEdge ? (screenOffset * (1 - offset)) - (panelHeight * offset) : 0
    }

    HoverHandler {
        id: globalHover
        enabled: root.toggleOnHover
        onHoveredChanged: {
            if (hovered)
                openRequest();
            else
                closeTimer.start();
        }
    }

    Timer {
        id: closeTimer
        interval: 300
        onTriggered: {
            if (!globalHover.hovered)
                closeRequest();
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: panelItem
            height: isHorizontal ? parent.height : root.panelHeight
            width: isHorizontal ? root.panelWidth : parent.width

            anchors {
                top: edge === Qt.TopEdge ? parent.top : undefined
                topMargin: edge === Qt.TopEdge ? (isHorizontal ? 0 : root.edgeMargin) : 0

                bottom: edge === Qt.BottomEdge ? parent.bottom : undefined
                bottomMargin: edge === Qt.BottomEdge ? (isHorizontal ? 0 : root.edgeMargin) : 0

                left: edge === Qt.LeftEdge ? parent.left : undefined
                leftMargin: edge === Qt.LeftEdge ? (isHorizontal ? root.edgeMargin : 0) : 0

                right: edge === Qt.RightEdge ? parent.right : undefined
                rightMargin: edge === Qt.RightEdge ? (isHorizontal ? root.edgeMargin : 0) : 0
            }

            Loader {
                anchors.fill: parent
                sourceComponent: root.cornerMode ? cornerShapeComp : panelShapeComp
            }

            WrapperItem {
                id: contentWrapper
                width: parent.width
                height: parent.height
                topMargin: root._mTop
                bottomMargin: root._mBottom
                leftMargin: root._mLeft
                rightMargin: root._mRight

                // Behavior on height {
                //     NumberAnimation {
                //         duration: 300
                //         easing.type: Easing.InOutCubic
                //     }
                // }
                // // Behavior on width {
                // //     NumberAnimation {
                // //         duration: 300
                // //         easing.type: Easing.Out
                // //     }
                // // }
                Loader {
                    id: contentLoader
                    active: root.opened || unloadDelayTimer.running
                    asynchronous: root.asynchronousLoad
                    sourceComponent: root.contentComponent
                    onItemChanged: root._syncPanelSize()
                }
            }

            Component {
                id: panelShapeComp
                PanelShape {
                    anchors.fill: parent
                    bgColor: Theme.background
                    borderColor: root.opened ? Theme.borderColor : "transparent"
                    edge: root.edge
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
                    borderColor: root.opened ? Theme.borderColor : "transparent"
                    edge: root.edge
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
