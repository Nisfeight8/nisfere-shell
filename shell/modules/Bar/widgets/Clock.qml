import QtQuick
import Quickshell
import qs.core
import qs.services

BarWidget {
    id: clockWidget

    property bool opened: false

    bgColor: "transparent"
    spacing: 8

    LucideIcon {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.selected
        size: 16
        icon: "calendar"
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.foreground
        font.bold: true
        font.family: Theme.fontName
        font.pixelSize: 14
        // Was sysClock.date from a locally-owned SystemClock — now
        // reads from the shared TimeService singleton (see
        // services/TimeService.qml) instead of owning its own clock.
        text: Qt.formatDateTime(TimeService.date, "ddd dd MMM • HH:mm")
    }

    Item {
        height: 1
        width: 4
    }

    // Notification Icon
    Item {
        anchors.verticalCenter: parent.verticalCenter
        height: 20
        visible: NotificationService.notifications.length > 0
        width: 20

        LucideIcon {
            anchors.centerIn: parent
            color: Theme.selected
            size: 16
            icon: "bell"
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: -6
            anchors.top: parent.top
            anchors.topMargin: -4
            color: Theme.color1
            height: 14
            radius: 7
            width: 14

            Text {
                anchors.centerIn: parent
                color: Theme.background
                font.bold: true
                font.pixelSize: 9
                text: NotificationService.notifications.length
            }
        }
    }

    HoverHandler {
        parent: clockWidget
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        parent: clockWidget
        onTapped: {
            const screenName = QsWindow.window?.screen?.name ?? "";
            const isOpenHere = ShellState.dashboardOpened && ShellState.activeScreenName === screenName;
            if (!isOpenHere && NotificationService.notifications.length > 0) {
                ShellState.currentDashboardTab = 3;
            }
            ShellState.toggleDashboard(screenName);
        }
    }
}
