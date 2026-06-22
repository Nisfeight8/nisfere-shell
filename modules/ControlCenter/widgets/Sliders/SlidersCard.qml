import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"

GlassCard {
    Layout.fillWidth: true
    implicitHeight: slidersColumn.implicitHeight + 30

    ColumnLayout {
        id: slidersColumn

        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        Volume {
        }
        Mic {
        }
        Brightness {
        }
    }
}
