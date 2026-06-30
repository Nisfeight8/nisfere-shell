import QtQuick
import qs.core
import qs.services

BarWidget {
    id: powererBtn
    useGradient: true
    paddingX: 14

    LucideIcon {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.selected
        size: 18
        icon: "power"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        parent: powererBtn

        onClicked: ShellState.powerMenuOpened = !ShellState.powerMenuOpened
    }
}
