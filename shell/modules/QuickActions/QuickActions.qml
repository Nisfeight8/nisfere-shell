import QtQuick
import qs.core
import qs.services

BaseDrawer {
    id: root
    z: 10
    edge: Qt.BottomEdge
    minPanelWidth: Screen.width * 0.20
    minPanelHeight: Screen.height * 0.10
    openedRequest: ShellState.quickActionsOpened
    toggleOnHover: true

    onCloseRequest: {
        ShellState.quickActionsOpened = false;
        resetQuickActionTimer.restart();
    }
    onOpenedChanged: {
        if (opened)
            resetQuickActionTimer.stop();
        else
            resetQuickActionTimer.restart();
    }

    Timer {
        id: resetQuickActionTimer
        interval: 100
        onTriggered: ShellState.quickAction = ""
    }


    contentComponent: Component {
        QuickActionsContent {
            id: content
        }
    }
}
