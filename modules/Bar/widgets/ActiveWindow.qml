import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import qs.core

BarWidget {
    id: root

    readonly property var activeWin: ToplevelManager.activeToplevel
    readonly property bool hasWindow: activeWin !== null
    readonly property string iconName: hasWindow && windowClass !== "" ? Icons.getAppIcon(windowClass) : Icons.getAppIcon("desktop")
    readonly property string windowClass: hasWindow ? activeWin.appId : ""
    readonly property string windowTitle: hasWindow ? activeWin.title : "Desktop"

    useGradient: true

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.selected
        font.family: Theme.fontName
        font.pixelSize: 14
        text: root.iconName
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 13
        text: root.windowTitle.length > 40 ? root.windowTitle.substring(0, 40) + "..." : root.windowTitle
    }
    MouseArea {
        id: winMouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        parent: root
    }
    BarPopup {
        id: winPopup

        showPopup: winMouseArea.containsMouse
        targetItem: root

        ColumnLayout {
            spacing: 10

            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.foreground
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 17
                text: root.hasWindow ? root.windowClass : "System"
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 320
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.8
                text: root.hasWindow ? root.windowTitle : "You are viewing the Desktop."
                wrapMode: Text.Wrap
            }
            ScreencopyView {
                id: captureView

                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                captureSource: winPopup.showPopup ? root.activeWin : null
                constraintSize: Qt.size(320, 200)
                live: true
                visible: false
            }
            OpacityMask {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: captureView.height
                Layout.preferredWidth: captureView.width
                source: captureView
                visible: root.hasWindow && captureView.hasContent

                maskSource: Rectangle {
                    height: captureView.height
                    radius: Theme.radius
                    width: captureView.width
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.selected
                font.family: Theme.fontName
                font.pixelSize: 32
                text: root.iconName
                visible: !root.hasWindow
            }
        }
    }
}
