import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"
import "widgets/SlidersCard"
import "widgets/Toggles"

Item {
    id: pageStack

    readonly property int currentIndex: ShellState.controlCenterPageIndex

    implicitHeight: animLoader.implicitHeight

    // ── Page Components ───────────────────────────────────
    Component {
        id: mainPageComp

        ColumnLayout {
            spacing: 10

            PageTitle {
                Layout.fillWidth: true
                text: "Control Center"
            }

            Toggles {
                Layout.fillWidth: true
            }

            SlidersCard {
                Layout.fillWidth: true
            }
        }
    }

    Component {
        id: wifiPageComp
        WifiPage {
            onBackRequested: ShellState.controlCenterPageIndex = 0
        }
    }

    Component {
        id: btPageComp
        BluetoothPage {
            onBackRequested: ShellState.controlCenterPageIndex = 0
        }
    }

    Component {
        id: ethPageComp
        EthernetPage {
            onBackRequested: ShellState.controlCenterPageIndex = 0
        }
    }

    // ── Animated Loader ────────────────────────────────────
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
