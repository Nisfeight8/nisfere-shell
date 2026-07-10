pragma ComponentBehavior: Bound

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
    minPanelWidth: Screen.width / 4
    minPanelHeight: 300
    toggleOnHover: false
    onCloseRequest: ShellState.controlCenterOpened = false
    onOpenRequest: ShellState.controlCenterOpened = true
    onToggleRequest: ShellState.controlCenterOpened = !ShellState.controlCenterOpened

    contentComponent: Component {
        id: container
        Item {
            id: pageStack

            property int currentIndex: 0

            implicitHeight: animLoader.item?.implicitHeight ?? 0

            // ── Page Components ───────────────────────────────────────────
            Component {
                id: mainPageComp

                ColumnLayout {
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        color: Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 22
                        text: "Control Center"
                    }

                    Toggles {
                        Layout.fillWidth: true
                    }

                    SlidersCard {
                        Layout.fillWidth: true
                    }

                    BatteryCard {
                        Layout.fillWidth: true
                    }
                    // SystemStatsCard{
                    //     Layout.fillWidth: true
                    // }
                }
            }

            Component {
                id: wifiPageComp
                WifiPage {
                    onBackRequested: pageStack.currentIndex = 0
                }
            }

            Component {
                id: btPageComp
                BluetoothPage {
                    onBackRequested: pageStack.currentIndex = 0
                }
            }

            Component {
                id: ethPageComp
                EthernetPage {
                    onBackRequested: pageStack.currentIndex = 0
                }
            }

            // ── Animated Loader ───────────────────────────────────────────
            AnimLoader {
                id: animLoader
                width: parent.width

                sourceComp: {
                    switch (pageStack.currentIndex) {
                    case 0:
                        return mainPageComp;
                    case 1:
                        return wifiPageComp;
                    case 2:
                        return btPageComp;
                    case 3:
                        return ethPageComp;
                    default:
                        return mainPageComp;
                    }
                }
            }
        }
    }
}
