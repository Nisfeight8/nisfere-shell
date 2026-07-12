import QtQuick
import qs.core
import qs.services

BarWidget {
    id: launcherBtn

    useGradient: true

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.selected
        font.family: Theme.fontName
        font.pixelSize: 18
        text: "󰣇"
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        parent: launcherBtn

        onClicked: ShellState.appLauncherOpened = !ShellState.appLauncherOpened
    }
}
