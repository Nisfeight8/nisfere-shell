import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    anchors.fill: parent
    // Was missing entirely — rowLayout already correctly computes its
    // own implicit size bottom-up from its children (SideMenu's fixed
    // implicitWidth, the divider, and AnimLoader's own forwarded
    // content size), it just never reached root. Same fix as
    // Media.qml/Weather.qml, for the same reason (per-tab custom size).
    implicitWidth: rowLayout.implicitWidth
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
