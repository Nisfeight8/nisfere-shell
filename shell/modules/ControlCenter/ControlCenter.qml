import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"
import "widgets/Sliders"
import "widgets/Toggles"

BaseDrawer {
    id: controlCenterDrawer

    anchors.bottom: true
    anchors.top: true
    edge: Qt.RightEdge
    margins.bottom: Theme.panelBorderSize + Theme.radius
    margins.top: Theme.barHeight + Theme.radius
    opened: ShellState.controlCenterOpened
    panelHeight: Screen.height
    panelWidth: Screen.width / 4

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
