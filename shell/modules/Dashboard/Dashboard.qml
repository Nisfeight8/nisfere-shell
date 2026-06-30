import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"
import "widgets/Overview"

BaseDrawer {
    id: dashboard

    edge: Qt.TopEdge
    edgeMargin: 0
    opened: ShellState.dashboardOpened
    panelHeight: Screen.height / 2.3
    panelWidth: Screen.width / 2.2
    screenOffset: Theme.barHeight
    toggleOnHover: false

    onCloseRequest: ShellState.dashboardOpened = false
    onOpenRequest: ShellState.dashboardOpened = true
    onToggleRequest: ShellState.dashboardOpened = !ShellState.dashboardOpened

    contentComponent: Component {
        ColumnLayout {
            id: mainColumn
            anchors.fill: parent
            spacing: 10

            NavTabs {
                id: dashboardTabs
                Layout.fillWidth: true
                spacing: 10
                currentIndex: ShellState.currentDashboardTab
                onTabClicked: function (tabIndex) {
                    ShellState.currentDashboardTab = tabIndex;
                }
                tabModel: [
                    {
                        icon: "layout-dashboard",
                        title: "Overview"
                    },
                    {
                        icon: "music",
                        title: "Media"
                    },
                    {
                        icon: "sun",
                        title: "Weather"
                    },
                    {
                        icon: "bell",
                        title: "Alerts"
                    }
                ]
            }

            StackLayout {
                id: contentStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: ShellState.currentDashboardTab

                // ✅ Explicit Loaders - χωρίς Repeater, χωρίς race condition
                Loader {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    active: ShellState.currentDashboardTab === 0
                    asynchronous: true
                    sourceComponent: Component {
                        Overview {}
                    }
                }
                Loader {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    active: ShellState.currentDashboardTab === 1
                    asynchronous: true
                    sourceComponent: Component {
                        Media {}
                    }
                }
                Loader {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    active: ShellState.currentDashboardTab === 2
                    asynchronous: true
                    sourceComponent: Component {
                        Weather {}
                    }
                }
                Loader {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    active: ShellState.currentDashboardTab === 3
                    asynchronous: true
                    sourceComponent: Component {
                        Notifications {}
                    }
                }
            }
        }
    }
}
