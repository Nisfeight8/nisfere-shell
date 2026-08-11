import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    anchors.fill: parent

    // No implicitWidth — same reasoning as Overview/Notifications:
    // width is forced top-down via tabsLoader's Layout.fillWidth, so
    // this tab has no real use for one.
    //
    // implicitHeight DOES matter (tabsLoader has no Layout.fillHeight)
    // — rowLayout computes the real bottom-up answer from its own
    // children (SideMenu, the divider, and whichever of Tasks/
    // FocusTimer is currently loaded), so we just forward that.
    implicitHeight: rowLayout.implicitHeight

    Component {
        id: tasksComp
        Tasks {
            uiScale: root.uiScale
        }
    }
    Component {
        id: focusComp
        FocusTimer {
            uiScale: root.uiScale
        }
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 12 * root.uiScale

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
