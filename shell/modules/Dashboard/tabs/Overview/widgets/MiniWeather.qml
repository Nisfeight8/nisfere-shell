import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

GlassCard {
    id: miniWeatherCard

    readonly property var weatherVisuals: Icons.getWeatherInfo(WeatherService.weatherCode, WeatherService.isDay)

    // Was missing here (MiniClock has it) — without this, the Loader
    // in Overview.qml that gives this card Layout.fillWidth/fillHeight
    // has nothing to actually stretch: this card would sit at its own
    // implicit (content) size inside whatever cell it's given, instead
    // of filling it like MiniClock does. Added for consistency with
    // the rest of the grid — flag if that wasn't the intent.
    anchors.fill: parent

    // Was a fixed magic constant (120), same issue as MiniClock's old
    // refSize: disconnected from the card's actual rendered size, so
    // it only "looked" responsive by coincidence. Now derived from
    // the real size, same pattern as MiniClock.
    readonly property real refSize: Math.min(miniWeatherCard.width, miniWeatherCard.height)

    // Previous implicitWidth/implicitHeight (computed from mainLayout)
    // removed — dead code now that anchors.fill above determines the
    // actual size; nothing upstream ever read it since the containing
    // Loader forces fillWidth/fillHeight regardless.

    ColumnLayout {
        id: mainLayout

        anchors.fill: parent
        anchors.margins: 15
        spacing: Math.max(5, miniWeatherCard.refSize * 0.1)

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.max(5, miniWeatherCard.refSize * 0.08)

            LucideIcon {
                id: weatherIcon
                Layout.alignment: Qt.AlignVCenter
                color: miniWeatherCard.weatherVisuals.color
                icon: miniWeatherCard.weatherVisuals.icon
                size: Math.max(24, miniWeatherCard.refSize * 0.35)
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
