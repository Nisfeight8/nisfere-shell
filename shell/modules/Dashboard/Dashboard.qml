import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"
import "widgets/Overview"
import "widgets/Productivity"

BaseDrawer {
    id: dashboard

    edge: Qt.TopEdge
    edgeMargin: 0
    opened: ShellState.dashboardOpened
    screenOffset: Theme.barHeight
    toggleOnHover: false
    minPanelWidth: Screen.width * 0.46
    minPanelHeight: Screen.height * 0.43

    onCloseRequest: ShellState.dashboardOpened = false
    onOpenRequest: ShellState.dashboardOpened = true
    onToggleRequest: ShellState.dashboardOpened = !ShellState.dashboardOpened

    contentComponent: Component {
        Item {
            id: wrapper

            Component {
                id: overviewComp
                Overview {}
            }
            Component {
                id: mediaComp
                Media {}
            }
            Component {
                id: weatherComp
                Weather {}
            }
            Component {
                id: notificationsComp
                Notifications {}
            }
            Component {
                id: productivityComp
                Productivity {}
            }

            ColumnLayout {
                id: mainColumn
                anchors.fill: parent
                spacing: 15

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 15

                    NavTabs {
                        id: navTabs
                        width: wrapper.implicitWidth
                        height: 30
                        currentIndex: ShellState.currentDashboardTab
                        onTabClicked: index => ShellState.currentDashboardTab = index
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
                            },
                            {
                                icon: "brain",
                                title: "Productivity"
                            },
                        ]
                    }
                }

                AnimLoader {
                    id: animLoader
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceComp: {
                        switch (ShellState.currentDashboardTab) {
                        case 0:
                            return overviewComp;
                        case 1:
                            return mediaComp;
                        case 2:
                            return weatherComp;
                        case 3:
                            return notificationsComp;
                        case 4:
                            return productivityComp;
                        default:
                            return overviewComp;
                        }
                    }
                }
            }
        }
    }
}
