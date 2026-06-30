import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"

GlassCard {
    Layout.fillWidth: true
    // implicitHeight will automatically adjust when the Loader disappears
    height: slidersColumn.implicitHeight + 15
    
    ColumnLayout {
        id: slidersColumn
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        // Mandatory Widgets: No Loader needed
        Volume {
            Layout.fillWidth: true
        }

        Mic {
            id: mic
            Layout.fillWidth: true
        }

        // Conditional Widget: Use Loader for memory/performance
        Loader {
            active: BrightnessService.isAvailable
            asynchronous: true
            source: "widgets/Brightness.qml"

            Layout.fillWidth: true
            Layout.preferredHeight: BrightnessService.isAvailable ?  mic.height : 0
        }
    }
}
