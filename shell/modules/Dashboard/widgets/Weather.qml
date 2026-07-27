import QtQuick
import QtQuick.Layouts

import qs.core
import qs.services

Item {
    id: root

    anchors.fill: parent
    // Was `implicitWidth: parent.width` / `implicitHeight: parent.height`
    // — same backwards implicit-size pattern as Media.qml/Overview.qml.
    // Now bottom-up from mainColumn, which (per your own "Bubble-up
    // implicit size" comments below) already correctly computes its own
    // implicit size from its children.
    implicitWidth: mainColumn.implicitWidth
    implicitHeight: mainColumn.implicitHeight

    function getDayName(dateString, index) {
        if (index === 0)
            return "Today";
        if (index === 1)
            return "Tomorrow";
        const date = new Date(dateString);
        const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        return days[date.getDay()];
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 15

        RowLayout {
            id: topRow

            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {

                spacing: 10

                GlassCard {
                    id: mainWeatherCard

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    implicitWidth: weatherRow.implicitWidth + 40
                    implicitHeight: weatherRow.implicitHeight + 40

                    RowLayout {
                        id: weatherRow

                        readonly property var visuals: Icons.getWeatherInfo(WeatherService.weatherCode, WeatherService.isDay)

                        anchors.centerIn: parent
                        spacing: 10

                        LucideIcon {
                            color: weatherRow.visuals.color
                            size: 60
                            icon: weatherRow.visuals.icon
                        }
                        ColumnLayout {
                            spacing: 5

                            Text {
                                color: Theme.foreground
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: 32
                                text: WeatherService.ready ? Math.round(WeatherService.temperature) + "°C" : "--°C"
                            }
                            Text {
                                color: Theme.foreground
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: 18
                                text: WeatherService.ready ? WeatherService.city : "Loading..."
                            }
                            Text {
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 16
                                opacity: 0.7
                                text: WeatherService.ready ? WeatherService.description : ""
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 10

                GlassCard {
                    id: feelsLikeCard

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    // ✅ Bubble-up implicit size
                    implicitWidth: feelsLikeRow.implicitWidth + 30
                    implicitHeight: feelsLikeRow.implicitHeight + 30

                    RowLayout {
                        id: feelsLikeRow

                        anchors.left: parent.left
                        anchors.margins: 15
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        LucideIcon {
                            size: 20
                            color: Theme.color1
                            icon: "flame"
                        }
                        Text {
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            opacity: 0.8
                            text: "Feels Like\n" + (WeatherService.ready ? Math.round(WeatherService.feelsLike) + "°C" : "--")
                        }
                    }
                }
                GlassCard {
                    id: humidityCard

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    implicitWidth: humidityRow.implicitWidth + 30
                    implicitHeight: humidityRow.implicitHeight + 30

                    RowLayout {
                        id: humidityRow

                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        LucideIcon {
                            color: Theme.color6
                            size: 20
                            icon: "droplets"
                        }
                        Text {
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            opacity: 0.8
                            text: "Humidity\n" + (WeatherService.ready ? WeatherService.humidity + "%" : "--")
                        }
                    }
                }
                GlassCard {
                    id: windCard

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    implicitWidth: windRow.implicitWidth + 30
                    implicitHeight: windRow.implicitHeight + 30

                    RowLayout {
                        id: windRow

                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        LucideIcon {
                            color: Theme.color2
                            size: 20
                            icon: "wind"
                        }
                        Text {
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            opacity: 0.8
                            text: "Wind\n" + (WeatherService.ready ? Math.round(WeatherService.windSpeed) + " km/h" : "--")
                        }
                    }
                }
            }
        }

        GlassCard {
            Layout.fillWidth: true
            implicitHeight: forecastTitleText.implicitHeight + 24

            Text {
                id: forecastTitleText

                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.foreground
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 18
                text: "7-Day Forecast"
            }
        }

        RowLayout {
            id: forecastRow

            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: WeatherService.dailyForecast

                delegate: GlassCard {
                    id: dayCard

                    readonly property var dayVisuals: Icons.getWeatherInfo(modelData.weatherCode, true)

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    implicitWidth: dayColumn.implicitWidth + 24
                    implicitHeight: dayColumn.implicitHeight + 40

                    ColumnLayout {
                        id: dayColumn

                        anchors.centerIn: parent
                        spacing: 7

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            color: index === 0 ? Theme.selected : Theme.foreground
                            font.bold: true
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            opacity: index === 0 ? 1.0 : 0.8
                            text: root.getDayName(modelData.date, index)
                        }

                        LucideIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: dayCard.dayVisuals.icon
                            color: dayCard.dayVisuals.color
                            size: 40
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 5

                            Text {
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 14
                                opacity: 0.5
                                text: modelData.minTempC + "°"
                            }
                            Text {
                                color: Theme.foreground
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: 15
                                text: modelData.maxTempC + "°"
                            }
                        }
                    }
                }
            }
        }
    }
}
