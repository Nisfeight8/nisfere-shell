import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import qs.core
import qs.services
import "widgets"

import "widgets/Overview"

BaseDrawer {
    id: topDashboard

    edge: Qt.TopEdge
    edgeMargin: 0
    opened: ShellState.topDashboardOpened
    panelHeight: Screen.height / 2.3
    panelWidth: Screen.width / 2.2
    screenOffset: Theme.barHeight
    toggleOnHover: false

    onCloseRequest: ShellState.topDashboardOpened = false
    onOpenRequest: ShellState.topDashboardOpened = true
    onToggleRequest: ShellState.topDashboardOpened = !ShellState.topDashboardOpened

    ColumnLayout {
        id: mainColumn

        anchors.fill: parent
        spacing: 10

        RowLayout {
            id: dashboardTabs

            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: [
                    {
                        icon: "󰋜",
                        title: "Overview"
                    },
                    {
                        icon: "󰎆",
                        title: "Media"
                    },
                    {
                        icon: "󰖐",
                        title: "Weather"
                    },
                    {
                        icon: "󰂚",
                        title: "Alerts"
                    }
                ]

                delegate: Item {
                    property bool isHovered: tabMouse.containsMouse
                    property bool isSelected: ShellState.currentDashboardTab === index

                    Layout.fillWidth: true
                    Layout.preferredHeight: 45

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            color: isSelected ? Theme.selected : Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 18
                            opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.4)
                            text: modelData.icon

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }
                            }
                        }
                        Text {
                            color: isSelected ? Theme.selected : Theme.foreground
                            font.bold: isSelected
                            font.family: Theme.fontName
                            font.pixelSize: 14
                            opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.4)
                            text: modelData.title

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }
                            }
                        }
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.selected
                        height: 3
                        opacity: isSelected ? 1 : 0
                        radius: 2
                        width: isSelected ? parent.width * 0.6 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                        Behavior on width {
                            NumberAnimation {
                                duration: 350
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                    MouseArea {
                        id: tabMouse

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: ShellState.currentDashboardTab = index
                    }
                }
            }
        }
        StackLayout {
            id: tabPages

            Layout.fillHeight: true
            Layout.fillWidth: true
            currentIndex: ShellState.currentDashboardTab

            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: ShellState.currentDashboardTab === 0
                asynchronous: true

                sourceComponent: Component {
                    Overview {
                    }
                }
            }

            // TAB 1: Media
            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: ShellState.currentDashboardTab === 1
                asynchronous: true

                sourceComponent: Component {
                    Media {
                    }
                }
            }

            // TAB 2: Weather
            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: ShellState.currentDashboardTab === 2
                asynchronous: true

                sourceComponent: Component {
                    Weather {
                    }
                }
            }

            // TAB 3: Notifications
            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: ShellState.currentDashboardTab === 3
                asynchronous: true

                sourceComponent: Component {
                    Notifications {
                    }
                }
            }
        }
    }
}
