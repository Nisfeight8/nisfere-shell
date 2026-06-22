import QtQuick
import Quickshell
import qs.core
import "widgets"
import "widgets/Workspaces"

PanelWindow {
    id: myBar

    color: Theme.background
    implicitHeight: Theme.barHeight

    anchors {
        left: true
        right: true
        top: true
    }

    Item {
        anchors.fill: parent

        LauncherButton {
            id: launcherButton
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }
        }
        Workspaces {
            id: workspacesWidget
            anchors {
                left: launcherButton.right
                leftMargin: 15
                verticalCenter: parent.verticalCenter
            }
        }
        ActiveWindow {
            id: activeWindowWidget
            anchors {
                left: workspacesWidget.right
                leftMargin: 15
                verticalCenter: parent.verticalCenter
            }
        }
        Clock {
            id: clockWidget
            anchors.centerIn: parent
        }
        TrayWidget {
            id: sysTrayWidget
            anchors {
                right: audioWidget.left
                rightMargin: 15
                verticalCenter: parent.verticalCenter
            }
        }
        AudioWidget {
            id: audioWidget
            anchors {
                right: keyboardWidget.left
                rightMargin: 15
                verticalCenter: parent.verticalCenter
            }
        }
        KeyboardWidget {
            id: keyboardWidget
            anchors {
                right: powerButton.left
                rightMargin: 15
                verticalCenter: parent.verticalCenter
            }
        }
        PowerButton {
            id: powerButton
            anchors {
                right: parent.right
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }
        }
    }
}