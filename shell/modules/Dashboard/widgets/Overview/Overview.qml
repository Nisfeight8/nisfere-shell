import QtQuick
import QtQuick.Layouts
import "widgets"

// Overview.qml
Item {
    id: root

    property int _readyCount: 0
    readonly property bool _allReady: _readyCount >= 4

    implicitWidth: _allReady ? rowLayout.implicitWidth : 400
    implicitHeight: _allReady ? rowLayout.implicitHeight : 400

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 10

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
