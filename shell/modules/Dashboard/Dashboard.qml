import QtQuick
import qs.core
import qs.services
import "widgets"
import "widgets/Overview"

BaseDrawer {
    id: dashboard

    edge: Qt.TopEdge
    edgeMargin: 0
    opened: ShellState.dashboardOpened
    screenOffset: Theme.barHeight
    toggleOnHover: false
    panelHeight: Screen.height / 3.4
    panelWidth: Screen.width / 2.5
    onCloseRequest: ShellState.dashboardOpened = false
    onOpenRequest: ShellState.dashboardOpened = true
    onToggleRequest: ShellState.dashboardOpened = !ShellState.dashboardOpened

    contentComponent: Component {
        Item {
            id: wrapper

            property real _lastWidth: 0
            property real _lastHeight: 0

            implicitWidth: _lastWidth
            implicitHeight: _lastHeight

            function _syncSize() {
                const item = animLoader.item;
                if (!item)
                    return;
                if (item.implicitWidth > 0)
                    _lastWidth = item.implicitWidth;
                if (item.implicitHeight > 0)
                    _lastHeight = item.implicitHeight + navTabs.height + col.spacing;
            }

            // ✅ Ενημερώνει το cache όποτε αλλάζει το φορτωμένο item ή το implicit size του
            Connections {
                target: animLoader.item
                function onImplicitWidthChanged() {
                    wrapper._syncSize();
                }
                function onImplicitHeightChanged() {
                    wrapper._syncSize();
                }
            }

            Component.onCompleted: {
                _syncSize();
            }

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

            Column {
                id: col
                spacing: 10

                NavTabs {
                    id: navTabs
                    width: wrapper.implicitWidth   // ✅ ακολουθεί το ήδη σταθεροποιημένο πλάτος
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
                        }
                    ]
                }

                AnimLoader {
                    id: animLoader
                    onItemChanged: wrapper._syncSize()
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
                        default:
                            return overviewComp;
                        }
                    }
                }
            }
        }
    }
}
