import QtQuick
import Quickshell
import qs.core
import qs.services

PanelWindow {
    id: root

    property Component contentComponent
    property int closeAnimationDuration: 300

    readonly property Item loadedItem: contentLoader.item
    property bool asynchronousLoad: true

    property int edge: Qt.LeftEdge
    property int edgeMargin: Theme.panelBorderSize
    readonly property bool isHorizontal: edge === Qt.LeftEdge || edge === Qt.RightEdge
    property real offset: opened ? 0 : 1
    property bool opened: false
    required property int panelHeight
    required property int panelWidth
    property int screenOffset: 0
    property bool toggleOnHover: true

    signal closeRequest
    signal openRequest
    signal toggleRequest

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: root.opened
    implicitHeight: root.panelHeight + (isHorizontal ? 0 : root.edgeMargin)
    implicitWidth: root.panelWidth + (isHorizontal ? root.edgeMargin : 0)
    visible: true

    Behavior on offset {
        NumberAnimation {
            duration: root.closeAnimationDuration
            easing.type: Easing.OutCubic
        }
    }

    onOpenedChanged: {
        if (!opened) {
            unloadDelayTimer.restart();
        } else {
            unloadDelayTimer.stop();
        }
    }

    Timer {
        id: unloadDelayTimer
        interval: root.closeAnimationDuration + 50
    }

    anchors {
        bottom: edge === Qt.BottomEdge ? true : false
        left: edge === Qt.LeftEdge ? true : false
        right: edge === Qt.RightEdge ? true : false
        top: edge === Qt.TopEdge ? true : false
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
            height: isHorizontal ? parent.height : panelHeight
            width: isHorizontal ? panelWidth : parent.width
            anchors {
                bottom: edge === Qt.TopEdge ? parent.bottom : undefined
                left: edge === Qt.RightEdge ? parent.left : undefined
                right: edge === Qt.LeftEdge ? parent.right : undefined
                top: edge === Qt.BottomEdge ? parent.top : undefined
            }

            PanelShape {
                anchors.fill: parent
                bgColor: Theme.background
                borderColor: root.opened ? Theme.borderColor : "transparent"
                edge: root.edge
            }

            Item {
                id: internalContainer
                anchors.bottomMargin: edge === Qt.BottomEdge ? (30 - Theme.panelBorderSize) : 30
                anchors.fill: parent
                anchors.leftMargin: edge === Qt.LeftEdge ? (30 - Theme.panelBorderSize) : 30
                anchors.rightMargin: edge === Qt.RightEdge ? (30 - Theme.panelBorderSize) : 30
                anchors.topMargin: edge === Qt.TopEdge ? (30 - Theme.barHeight + 10) : 30

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    active: root.opened || unloadDelayTimer.running
                    asynchronous: root.asynchronousLoad
                    sourceComponent: root.contentComponent
                }
            }
        }
    }
}
