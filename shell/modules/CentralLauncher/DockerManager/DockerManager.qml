import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "containers"
import "images"
import "volumes"

Rectangle {
    id: root

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

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 10

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
