import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"
import "widgets/Overview"
import "widgets/Productivity"
import "widgets/Notifications"

Item {
    id: wrapper

    // Was missing entirely — mainColumn (a ColumnLayout) already
    // correctly auto-computes its OWN implicit size bottom-up from its
    // children (standard Layout behavior), but nothing forwarded that
    // up to wrapper's own implicit size, so it stayed at the default
    // (0) no matter what any tab actually needed. This is the other
    // half of Media.qml's own implicit-size fix — without this, a
    // tab's real content size never reaches DrawerContentHost /
    // DrawerGeometry, and every tab stays stuck at Dashboard's fixed
    // minPanelWidth/minPanelHeight regardless of what it actually needs.
    implicitWidth: mainColumn.implicitWidth
    implicitHeight: mainColumn.implicitHeight

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
                // Was `width: wrapper.implicitWidth` — wrapper (this
                // file's root Item) never binds its own implicitWidth
                // to anything (anchors.fill on the ColumnLayout doesn't
                // feed implicit size upward), so that was always 0,
                // regardless of how wide the drawer actually rendered.
                // NavTabs is already the sole child of a
                // Layout.fillWidth RowLayout — just let it fill that
                // directly instead of computing width by hand.
                Layout.fillWidth: true
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
