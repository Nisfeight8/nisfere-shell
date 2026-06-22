import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import qs.core
import qs.services

BarWidget {
    id: clockWidget

    property bool opened: false

    bgColor: "transparent"
    spacing: 8

    SystemClock {
        id: sysClock
        precision: SystemClock.Seconds
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.selected
        font.family: Theme.fontName
        font.pixelSize: 16
        text: ""
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.foreground
        font.bold: true
        font.family: Theme.fontName
        font.pixelSize: 14
        text: Qt.formatDateTime(sysClock.date, "ddd dd MMM • HH:mm")
    }
    Item {
        height: 1
        width: 4
    }
    Item {
        anchors.verticalCenter: parent.verticalCenter
        height: 20
        visible: NotificationService.notifications.length > 0
        width: 20

        Text {
            anchors.centerIn: parent
            color: Theme.selected
            font.family: Theme.fontName
            font.pixelSize: 16
            text: "󰂚"
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
    MouseArea {
        id: clockMouse

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        parent: clockWidget

        onClicked: {
            if (!ShellState.topDashboardOpened) {
                if (NotificationService.notifications.length > 0) {
                    ShellState.currentDashboardTab = 3;
                    console.log(ShellState.currentDashboardTab);
                } else {
                    ShellState.currentDashboardTab = 0;
                }
            }
            ShellState.topDashboardOpened = !ShellState.topDashboardOpened;
        }
    }
}
