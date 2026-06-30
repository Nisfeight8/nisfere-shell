import QtQuick
import QtQuick.Layouts
import "widgets"

RowLayout {
    spacing: 15

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1.5

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
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1.5
        spacing: 10

        Loader {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            asynchronous: true
            sourceComponent: Component {
                MiniWeather {}
            }
        }

        Loader {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            asynchronous: true
            sourceComponent: Component {
                MiniMedia {}
            }
        }

        Loader {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            asynchronous: true
            sourceComponent: Component {
                SystemInfoDetails {}
            }
        }
    }
}
