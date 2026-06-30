import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.core
import qs.services

PanelWindow {
    id: root

    property int bezelSize: Theme.panelBorderSize
    property color bgColor: Theme.background
    property color borderColor: Theme.borderColor
    property int cornerRadius: Theme.radius
    readonly property int topBarHeight: Theme.barHeight
    property int topBezelHeight: Theme.barHeight

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    mask: Region {
    }

    anchors {
        bottom: true
        left: true
        right: true
        top: true
    }
    // --- Top Border ---
    Rectangle {
        id: topBorderLine

        anchors.left: parent.left
        anchors.leftMargin: root.bezelSize
        anchors.right: parent.right
        anchors.rightMargin: root.bezelSize
        anchors.top: parent.top
        anchors.topMargin: root.topBarHeight
        color: Theme.borderColor
        height: Theme.widgetBorderWidth
        // opacity: ShellState.dashboardOpened || ShellState.anyPopupOpen ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
    }

    // --- Bottom Bezel ---
    Rectangle {
        id: bottomBorderLine

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: Theme.background
        height: Theme.panelBorderSize

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        Rectangle {
            anchors.bottom: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            color: Theme.borderColor
            height: Theme.widgetBorderWidth
            // opacity: ShellState.quakeTerminalOpened ? 0 : 1
        }
    }

    // --- Left Bezel ---
    Rectangle {
        id: leftBorderLine

        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: root.topBarHeight
        color: Theme.background
        width: Theme.panelBorderSize

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.right
            anchors.top: parent.top
            color: Theme.borderColor
            // opacity: ShellState.launcherOpened ? 0 : 1
            width: Theme.widgetBorderWidth
        }
    }

    // --- Right Bezel ---
    Rectangle {
        id: rightBorderLine

        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root.topBarHeight
        color: Theme.background
        width: Theme.panelBorderSize

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.left
            anchors.top: parent.top
            color: Theme.borderColor
            // opacity: ShellState.controlCenterOpened ? 0 : 1
            width: Theme.widgetBorderWidth
        }
    }
    ScreenCorner {
        anchors.left: parent.left
        anchors.leftMargin: root.bezelSize
        anchors.top: parent.top
        anchors.topMargin: root.topBarHeight
        // top-left (rotation: 0, default)
    }
    ScreenCorner {
        anchors.right: parent.right
        anchors.rightMargin: root.bezelSize
        anchors.top: parent.top
        anchors.topMargin: root.topBarHeight
        rotation: 90 // top-right
    }
    ScreenCorner {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        anchors.right: parent.right
        anchors.rightMargin: root.bezelSize
        rotation: 180 // bottom-right
    }
    ScreenCorner {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        anchors.left: parent.left
        anchors.leftMargin: root.bezelSize
        rotation: 270 // bottom-left
    }

    component ScreenCorner: Shape {
        property real bw: Theme.widgetBorderWidth
        property real offset: bw / 2.0
        property int r: root.cornerRadius

        antialiasing: true
        height: r
        preferredRendererType: Shape.CurveRenderer
        width: r

        ShapePath {
            fillColor: Theme.background
            startX: 0
            startY: 0
            strokeColor: Theme.background

            PathLine {
                x: r
                y: 0
            }
            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: r
                radiusY: r
                x: 0
                y: r
            }
            PathLine {
                x: 0
                y: 0
            }
        }
        ShapePath {
            fillColor: "transparent"
            startX: r
            startY: offset
            strokeColor: Theme.borderColor
            strokeWidth: bw

            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: r - offset
                radiusY: r - offset
                x: offset
                y: r
            }
        }
    }
}
