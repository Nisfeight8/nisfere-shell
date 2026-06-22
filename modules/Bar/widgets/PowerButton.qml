import QtQuick
import qs.core
import qs.services

BarWidget {
    id: powererBtn
    useGradient: true
    paddingX: 14

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.selected
        font.family: Theme.fontName
        font.pixelSize: 18
        text: ""
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        parent: powererBtn

        onClicked: ShellState.powerMenuOpened = !ShellState.powerMenuOpened
    }
}
