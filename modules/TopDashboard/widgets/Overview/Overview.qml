import QtQuick
import QtQuick.Layouts
import "widgets"

RowLayout {
    //anchors.fill: parent
    spacing: 15

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1.5

        MiniClock {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1.5
        spacing: 10

        MiniWeather {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: 1
        }
        MiniMedia {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: 1
        }
        SystemInfoDetails {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: 1
        }
    }
}
