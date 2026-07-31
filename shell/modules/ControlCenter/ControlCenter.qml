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
    minPanelWidth: 480
    minPanelHeight: 300
    toggleOnHover: false

    onCloseRequest: ShellState.controlCenterOpened = false

    contentComponent: Component {
        ControlCenterContent {}
    }
}
