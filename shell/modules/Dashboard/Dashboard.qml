import QtQuick
import qs.core
import qs.services

BaseDrawer {
    id: root
    z: 10
    edge: Qt.TopEdge
    edgeMargin: 0
    screenOffset: Theme.barHeight
    minPanelWidth: Screen.width * 0.45
    minPanelHeight: Screen.height * 0.45
    toggleOnHover: false
    openedRequest: ShellState.dashboardOpened

    onCloseRequest: ShellState.dashboardOpened = false

    contentComponent: Component {
        DashboardContent {}
    }
}
