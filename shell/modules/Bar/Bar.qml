import QtQuick
import QtQuick.Layouts
import qs.core
import "widgets"
import "widgets/Workspaces"
import "widgets/InternalTrayWidget"

Item {
    id: myBar

    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
    }
    implicitHeight: Theme.barHeight
    height: Theme.barHeight

    // Item has no color property of its own — explicit background
    // rect where the window used to just set `color:` directly.
    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    Item {
        anchors.fill: parent

        // Was individual anchor-chaining (left: previousWidget.right,
        // separate leftMargin per widget) — fragile to reordering, and
        // any widget that becomes invisible (e.g. TrayWidget when
        // trayRepeater.count === 0) leaves a gap instead of closing up,
        // since anchors don't know about visibility. RowLayout handles
        // both for free, and matches the right cluster's pattern —
        // one consistent way to arrange bar widgets, not two.
        RowLayout {
            id: leftCluster
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }
            spacing: 15

            LauncherButton {
                id: launcherButton
            }
            Workspaces {
                id: workspacesWidget
            }
            ActiveWindow {
                id: activeWindowWidget
            }
        }

        Clock {
            id: clockWidget
            anchors.centerIn: parent
        }

        RowLayout {
            id: rightCluster
            anchors {
                right: parent.right
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }
            spacing: 15

            RecordingIndicator {
                id: recordingIndicator
            }
            // SystemStatsWidget {
            //     id: systemStats
            // }
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
