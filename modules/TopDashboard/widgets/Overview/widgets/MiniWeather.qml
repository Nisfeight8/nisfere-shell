import QtQuick
import QtQuick.Layouts

import qs.core
import qs.services

GlassCard {
    id: miniWeatherCard

    readonly property real refSize: Math.min(width, height)
    readonly property var weatherVisuals: Icons.getWeatherInfo(WeatherService.weatherCode, WeatherService.isDay)

    Layout.fillHeight: true
    Layout.fillWidth: true

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Math.max(5, miniWeatherCard.refSize * 0.1)
        width: parent.width * 0.9

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            spacing: Math.max(5, miniWeatherCard.refSize * 0.08)

            Text {
                Layout.alignment: Qt.AlignVCenter
                color: miniWeatherCard.weatherVisuals.color
                font.family: Theme.fontName
                font.pixelSize: Math.max(24, miniWeatherCard.refSize * 0.35)
                text: miniWeatherCard.weatherVisuals.icon

                SequentialAnimation on opacity {
                    loops: Animation.Infinite

                    NumberAnimation {
                        duration: 2000
                        easing.type: Easing.InOutSine
                        to: 0.8
                    }
                    NumberAnimation {
                        duration: 2000
                        easing.type: Easing.InOutSine
                        to: 1.0
                    }
                }
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                color: Theme.foreground
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: Math.max(18, miniWeatherCard.refSize * 0.28)
                text: WeatherService.ready ? Math.round(WeatherService.temperature) + "°C" : "--°C"
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.foreground
            opacity: 0.1
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.foreground
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: Math.max(12, miniWeatherCard.refSize * 0.15)
                text: WeatherService.ready ? WeatherService.city : "Loading..."
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: Math.max(10, miniWeatherCard.refSize * 0.10)
                opacity: 0.6
                text: WeatherService.ready ? WeatherService.description : ""
            }
        }
    }
}
