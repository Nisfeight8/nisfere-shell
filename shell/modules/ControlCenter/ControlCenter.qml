import QtQuick
import qs.core
import qs.services

BaseDrawer {
    id: root
    z: 10
    cornerMode: true
    edge: Qt.RightEdge
    
    screenOffset: Theme.barHeight
    openedRequest: ShellState.controlCenterOpened
    minPanelWidth: Screen.width / 4
    minPanelHeight: 300
    toggleOnHover: false

    onCloseRequest: ShellState.controlCenterOpened = false

    contentComponent: Component {
        ControlCenterContent {}
    }
}
