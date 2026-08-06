import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "containers"
import "images"
import "volumes"

Rectangle {
    id: root

    // Was completely missing — this root had neither anchors.fill nor
    // any implicit size, meaning it likely rendered at its bare
    // default (0×0) regardless of whatever space DashboardContent's
    // AnimLoader actually had available (a Loader does NOT auto-
    // stretch a loaded item that doesn't anchor itself — same lesson
    // as MiniClock/MiniWeather earlier in this shell's cleanup).
    // Fixed size for the same reason as Settings.qml/SystemMonitorTool
    // — standalone top-level Dashboard component, no floor/ceiling
    // system protecting it, and tab content (Containers/Images/
    // Volumes) shouldn't resize the whole panel when you switch tabs.
    anchors.fill: parent
    implicitWidth: 820
    implicitHeight: 600

    property int currentTab: 0

    // ✅ Lazy load flags για tabs - μόνο true→true ποτέ false
    // (reset γίνεται αυτόματα όταν καταστρέφεται ο DockerManager)
    property bool imagesLoaded: false
    property bool volumesLoaded: false

    onCurrentTabChanged: {
        if (currentTab === 1)
            imagesLoaded = true;
        if (currentTab === 2)
            volumesLoaded = true;
    }

    color: "transparent"

    // ✅ FIX 1: Άμεσο πρώτο request - δεν περιμένουμε 3 δευτερόλεπτα
    Component.onCompleted: DockerService.requestDockerStats()

    Timer {
        id: dockerRefreshTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: DockerService.requestDockerStats()
    }
    // Explicit stop on destruction — turned out to be the actual fix,
    // not just defensive redundancy: Loader's item destruction on a
    // sourceComponent swap isn't always synchronous (there's a brief
    // deferred-deletion window), so without this the Timer could still
    // fire once more in that gap. Stopping it here happens
    // synchronously the moment destruction begins.
    Component.onDestruction: dockerRefreshTimer.stop()

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 10

        // Own small row, entirely separate from the tab bar below —
        // just the X, right-aligned. Previously tried nesting it as a
        // sibling of the tab-bar Rectangle in the same RowLayout, but
        // that inflated the tab bar's size — keeping it fully
        // separate avoids touching the tab bar's own layout at all.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            Item {
                Layout.fillWidth: true
            }

            // Same "X" convention as SystemMonitorTool/Settings —
            // ShellState.closeResumableComponent() both closes the
            // dashboard AND forgets this as the backgrounded/resumable
            // tool.
            IconButton {
                icon: "x"
                size: 28
                iconSize: 13
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.color1
                tooltipText: "Close"
                onTapped: ShellState.closeResumableComponent()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            border.color: Theme.borderColor
            border.width: Theme.widgetBorderWidth
            radius: Theme.radius
            color: Theme.backgroundAlt

            NavTabs {
                id: dockerTabs
                anchors.fill: parent
                anchors.margins: 5
                spacing: 10
                currentIndex: root.currentTab
                onTabClicked: function (tabIndex) {
                    root.currentTab = tabIndex;
                }
                tabModel: [
                    {
                        title: "Containers",
                        icon: "box"
                    },
                    {
                        title: "Images",
                        icon: "layers"
                    },
                    {
                        title: "Volumes",
                        icon: "database"
                    }
                ]
            }
        }

        StackLayout {
            id: mainContent
            Layout.fillHeight: true
            Layout.fillWidth: true
            currentIndex: root.currentTab

            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: true
                sourceComponent: Component {
                    ContainersWidget {}
                }
            }

            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: imagesLoaded
                sourceComponent: Component {
                    ImagesWidget {}
                }
            }

            // TAB 2: Volumes
            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: volumesLoaded
                sourceComponent: Component {
                    VolumesWidget {}
                }
            }
        }
    }
}
