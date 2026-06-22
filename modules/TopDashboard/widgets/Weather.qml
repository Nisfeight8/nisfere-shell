import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.core
import qs.services

Item {
    id: root

    function getDayName(dateString, index) {
        if (index === 0)
            return "Today";
        if (index === 1)
            return "Tomorrow";
        const date = new Date(dateString);
        const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        return days[date.getDay()];
    }

    anchors.fill: parent

    ColumnLayout {
        id: mainColumn

        anchors.fill: parent
        spacing: 15

        RowLayout {
            id: topRow

            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: 1 
            spacing: 10

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 10

                GlassCard  {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    

                    RowLayout {
                        readonly property var visuals: Icons.getWeatherInfo(WeatherService.weatherCode, WeatherService.isDay)

                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            color: parent.visuals.color
                            font.family: Theme.fontName
                            font.pixelSize: 80
                            text: parent.visuals.icon
                        }
                        ColumnLayout {
                            spacing: 5

                            Text {
                                color: Theme.foreground
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: 38
                                text: WeatherService.ready ? Math.round(WeatherService.temperature) + "°C" : "--°C"
                            }
                            Text {
                                color: Theme.foreground
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: 20
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
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    RowLayout {
                        id: infoLayout

                        anchors.left: parent.left
                        anchors.margins: 15
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            color: Theme.color1
                            font.family: Theme.fontName
                            font.pixelSize: 20
                            text: "󰈸"
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
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    RowLayout {
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            color: Theme.color6
                            font.family: Theme.fontName
                            font.pixelSize: 20
                            text: ""
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
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    RowLayout {
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            color: Theme.color2
                            font.family: Theme.fontName
                            font.pixelSize: 20
                            text: "󰖝"
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

            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: WeatherService.dailyForecast

                delegate: GlassCard {
                    id: dayCard

                    readonly property var dayVisuals: Icons.getWeatherInfo(modelData.weatherCode, true)

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    

                    ColumnLayout {
                        id: dayColumn

                        anchors.centerIn: parent
                        height: parent.height - 24
                        spacing: 7
                        width: parent.width - 24

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            color:  index === 0 ? Theme.selected : Theme.foreground
                            font.bold: true
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            opacity: index === 0 ? 1.0 : 0.8
                            text: root.getDayName(modelData.date, index)
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            color: dayCard.dayVisuals.color
                            font.family: Theme.fontName
                            font.pixelSize: 32
                            text: dayCard.dayVisuals.icon
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
