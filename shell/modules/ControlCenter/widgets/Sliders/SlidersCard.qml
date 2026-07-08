import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"

GlassCard {
    Layout.fillWidth: true

    // implicitHeight (όχι height!) ← ColumnLayout το χρειάζεται για layout
    // +30 = 15 (top margin) + 15 (bottom margin)
    implicitHeight: slidersColumn.implicitHeight + 15

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
            active: BrightnessService.isAvailable
            asynchronous: true
            source: "widgets/Brightness.qml"
            Layout.fillWidth: true
            Layout.preferredHeight: BrightnessService.isAvailable ? mic.implicitHeight : 0
            //                                                       ↑ implicitHeight όχι height
        }
    }
}
