import QtQuick
import QtQuick.Layouts
import "widgets"

// Overview.qml
Item {
    id: root

    property int _readyCount: 0
    readonly property bool _allReady: _readyCount >= 4
    anchors.fill: parent
    implicitWidth: parent.width
    implicitHeight: parent.height


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
