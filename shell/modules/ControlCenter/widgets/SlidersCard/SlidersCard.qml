import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"

GlassCard {
    Layout.fillWidth: true

    implicitHeight: slidersColumn.implicitHeight + 30

    Component {
        id: brightnessComp
        Brightness {}
    }

    ColumnLayout {
        id: slidersColumn
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        Volume {
            Layout.fillWidth: true
        }

        Mic {
            id: mic
            Layout.fillWidth: true
        }

        Loader {
            id: brightnessLoader
            active: BrightnessService.isAvailable
            visible: BrightnessService.isAvailable
            asynchronous: true
            sourceComponent: brightnessComp
            Layout.fillWidth: true
            Layout.preferredHeight: BrightnessService.isAvailable ? brightnessLoader.implicitHeight : 0
        }
    }
}
