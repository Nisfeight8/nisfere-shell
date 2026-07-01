import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"
import "widgets/Sliders"
import "widgets/Toggles"

BaseDrawer {
    id: controlCenterDrawer

    cornerMode: true
    edge: Qt.RightEdge

    anchors.top: true
    margins.top: Theme.barHeight
    opened: ShellState.controlCenterOpened
    panelHeight: 650
    panelWidth: Screen.width / 4
    toggleOnHover: false

    onCloseRequest: ShellState.controlCenterOpened = false
    onOpenRequest: ShellState.controlCenterOpened = true
    onToggleRequest: ShellState.controlCenterOpened = !ShellState.controlCenterOpened

    contentComponent: Component {
        StackLayout {
            id: pageStack
            anchors.fill: parent
            currentIndex: 0

            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: pageStack.currentIndex === 0
                asynchronous: true
                sourceComponent: mainPageComp
            }
            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: pageStack.currentIndex === 1
                asynchronous: true
                sourceComponent: Component {
                    WifiPage {
                        onBackRequested: pageStack.currentIndex = 0
                    }
                }
            }
            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: pageStack.currentIndex === 2
                asynchronous: true
                sourceComponent: Component {
                    BluetoothPage {
                        onBackRequested: pageStack.currentIndex = 0
                    }
                }
            }
            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: pageStack.currentIndex === 3
                asynchronous: true
                sourceComponent: Component {
                    EthernetPage {
                        onBackRequested: pageStack.currentIndex = 0
                    }
                }
            }

            Component {
                id: mainPageComp
                Item {
                    anchors.fill: parent
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 20
                        Text {
                            color: Theme.foreground
                            font.bold: true
                            font.family: Theme.fontName
                            font.pixelSize: 22
                            text: "Control Center"
                        }
                        Toggles {}
                        SlidersCard {}
                        BatteryCard {}
                        SystemStatsCard {}
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
    }
}
