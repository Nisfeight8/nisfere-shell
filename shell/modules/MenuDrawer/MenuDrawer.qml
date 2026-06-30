import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets/WallpaperManager"
import "widgets/DockerManager"

BaseDrawer {
    id: menuDrawer

    edge: Qt.BottomEdge
    focusable: opened
    opened: ShellState.menuDrawerOpened
    panelHeight: Screen.height / 2.0
    panelWidth: Screen.width / 2.0

    // ✅ Χωρίς lazy load flags - δεν θέλουμε keep-alive
    property int currentAppIndex: -1
    property string currentAppTitle: "Nisfere Tools"

    property var appMenu: [
        {
            title: "Wallpapers",
            icon: "image",
            index: 0
        },
        {
            title: "Docker",
            icon: "box",
            index: 1
        }
    ]

    onCloseRequest: ShellState.menuDrawerOpened = false
    onOpenRequest: ShellState.menuDrawerOpened = true
    onToggleRequest: ShellState.menuDrawerOpened = !ShellState.menuDrawerOpened

    contentComponent: Component {
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.padding
            spacing: 15

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 15

                Rectangle {
                    width: 30
                    height: 30
                    radius: Theme.radius
                    color: backMouse.containsMouse ? Theme.backgroundAlt : "transparent"
                    visible: currentAppIndex !== -1

                    LucideIcon {
                        anchors.centerIn: parent
                        icon: "chevron-left"
                        size: 20
                        color: Theme.foreground
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            currentAppIndex = -1;
                            currentAppTitle = "Nisfere Tools";
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: currentAppTitle
                    font.family: Theme.fontName
                    font.pixelSize: 18
                    font.bold: true
                    color: Theme.foreground
                    verticalAlignment: Text.AlignVCenter
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: currentAppIndex + 1

                // Index 0: Menu List
                ListView {
                    model: appMenu
                    spacing: 10

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 60
                        radius: Theme.radius
                        color: itemMouse.containsMouse ? Theme.backgroundAlt : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 20

                            LucideIcon {
                                icon: modelData.icon
                                size: 24
                                color: Theme.selected
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.title
                                font.family: Theme.fontName
                                font.pixelSize: 16
                                color: Theme.foreground
                            }
                            LucideIcon {
                                icon: "chevron-right"
                                size: 18
                                color: Theme.foreground
                                opacity: 0.5
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                currentAppTitle = modelData.title;
                                currentAppIndex = modelData.index;
                            }
                        }
                    }
                }

                // Index 1: Wallpaper Manager
                // ✅ active: μόνο όταν drawer ανοιχτό ΚΑΙ επιλεγμένο - χωρίς asynchronous γιατί μικρό
                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: currentAppIndex === 0
                    sourceComponent: Component {
                        WallpaperManager {}
                    }
                }

                // Index 2: Docker Manager
                // ✅ Καταστρέφεται όταν φύγεις → timer σταματά. Ξαναφτιάχνεται → data από singleton
                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: currentAppIndex === 1
                    sourceComponent: Component {
                        DockerManager {}
                    }
                }
            }
        }
    }
}
