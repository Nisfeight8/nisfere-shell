import QtQuick
import QtQuick.Layouts
import qs.core
import "widgets"

// Overview.qml
Item {
    id: root

    property int _readyCount: 0
    readonly property bool _allReady: _readyCount >= 4
    anchors.fill: parent
    // Was `implicitWidth: parent.width` / `implicitHeight: parent.height`
    // — implicit size bound to the PARENT's actual size, backwards from
    // how implicit/actual are meant to flow (implicit: child->parent,
    // actual: parent->child; see the Quickshell sizing docs). Harmless
    // today only because DashboardContent.qml's own implicit size is
    // ALSO not wired up yet, so this never gets read by anything — but
    // if that ever gets fixed, this becomes a genuine circular binding
    // (parent's actual <- this implicit <- parent's actual <- ...).
    // anchors.fill already gives this the correct actual size; these
    // two lines were both redundant and a latent trap.

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 10
        // Was tracked (_readyCount/_allReady) but never used — the 4
        // Loaders below are asynchronous, so without this they'd each
        // pop in individually whenever they happen to finish, at
        // slightly different times. Fading the whole grid in together
        // once ALL 4 are ready reads as one clean reveal instead.
        opacity: root._allReady ? 1 : 0
        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                asynchronous: true
                sourceComponent: Component {
                    MiniClock {}
                }
                onLoaded: root._readyCount++
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: implicitWidth * 1.4
            spacing: 10
            Loader {
                asynchronous: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: Component {
                    MiniWeather {}
                }
                onLoaded: root._readyCount++
            }
            Loader {
                asynchronous: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: Component {
                    MiniMedia {}
                }
                onLoaded: root._readyCount++
            }
            Loader {
                asynchronous: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: Component {
                    SystemInfoDetails {}
                }
                onLoaded: root._readyCount++
            }
        }
    }
}
