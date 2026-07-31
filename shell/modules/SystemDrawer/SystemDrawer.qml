import QtQuick
import qs.core
import qs.services

BaseDrawer {
    id: root
    z: 10
    cornerMode: true
    edge: Qt.LeftEdge
    screenOffset: Theme.barHeight
    openedRequest: ShellState.systemDrawerOpened
    minPanelWidth: 480
    minPanelHeight: 300
    onCloseRequest: ShellState.systemDrawerOpened = false
    onOpenedChanged: if (opened)
        UpdateService.loadCached()

    contentComponent: Component {
        SystemDrawerContent {}
    }
}
