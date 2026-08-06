import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    anchors.fill: parent

    // No implicitWidth — same reasoning as Overview/Notifications:
    // width is forced top-down via tabsLoader's Layout.fillWidth, so
    // this tab has no real use for one. The previous `750` was a
    // guess above minContentWidth (500), which would cause the exact
    // same drawer-panel width-jump bug we fixed on those other tabs.
    //
    // implicitHeight DOES matter (tabsLoader has no Layout.fillHeight)
    // — but rowLayout already computes the real bottom-up answer from
    // its own children (SideMenu, the divider, and whichever of
    // Tasks/FocusTimer is currently loaded), so we just forward that
    // instead of guessing a number by hand. Keeps this correct
    // automatically if SideMenu/Tasks/FocusTimer's own sizes ever
    // change, with nothing to remember to update here.
    implicitHeight: rowLayout.implicitHeight

    Component {
        id: tasksComp
        Tasks {}
    }
    Component {
        id: focusComp
        FocusTimer {}
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 12

        SideMenu {
            Layout.fillHeight: true
            currentIndex: ShellState.dashboardTabsCurrentProductivityTab
            onTabClicked: index => ShellState.dashboardTabsCurrentProductivityTab = index
            menuModel: [
                {
                    icon: "list-checks",
                    title: "Tasks"
                },
                {
                    icon: "timer",
                    title: "Focus"
                },
            ]
        }

        // Divider
        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: Theme.borderColor
            opacity: 0.4
        }

        AnimLoader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComp: ShellState.dashboardTabsCurrentProductivityTab === 0 ? tasksComp : focusComp
        }
    }
}
