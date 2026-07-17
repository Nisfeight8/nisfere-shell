import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import "widgets"
import "widgets/Workspaces"
import "widgets/InternalTrayWidget"

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

        // ── Right-side cluster ────────────────────────────────────
        // RowLayout instead of manual anchor chains — conditionally
        // visible widgets (BatteryWidget on desktops with no battery,
        // and any future opt-in widgets like a recording indicator or
        // now-playing widget) collapse their gap automatically here,
        // rather than leaving a dead 15px+width hole the way anchored
        // `right: X.left` chains do when X.visible turns false.
        RowLayout {
            id: rightCluster
            anchors {
                right: parent.right
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }
            spacing: 15

            TrayWidget {
                id: sysTrayWidget
            }
            BatteryWidget {
                id: batteryWidget
            }
            AudioWidget {
                id: audioWidget
            }
            KeyboardWidget {
                id: keyboardWidget
            }
            InternalTrayWidget {
                id: internalSystemTrayWidget
            }
            PowerButton {
                id: powerButton
            }
        }
    }
}
