import QtQuick
import QtQuick.Layouts
import "widgets"

Item {
    id: root

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 10

        ColumnLayout {
            id: leftColumn
            Layout.fillHeight: true
            Layout.fillWidth: true

            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                asynchronous: true
                sourceComponent: Component {
                    MiniClock {}
                }
            }
        }

        ColumnLayout {
            id: rightColumn
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: rightColumn.implicitWidth * 1.4
            spacing: 10

            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                asynchronous: true
                sourceComponent: Component {
                    MiniWeather {}
                }
            }
            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                asynchronous: true
                sourceComponent: Component {
                    MiniMedia {}
                }
            }
            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                asynchronous: true
                sourceComponent: Component {
                    SystemInfoDetails {}
                }
            }
        }
    }
}
