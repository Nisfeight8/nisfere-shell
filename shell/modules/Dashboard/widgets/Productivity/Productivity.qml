import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    anchors.fill: parent

    Component {
        id: tasksComp
        Tasks {}
    }
    Component {
        id: focusComp
        FocusTimer {}
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        SideMenu {
            Layout.fillHeight: true
            currentIndex: ShellState.currentProductivityTab
            onTabClicked: index => ShellState.currentProductivityTab = index
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
            sourceComp: ShellState.currentProductivityTab === 0 ? tasksComp : focusComp
        }
    }
}
