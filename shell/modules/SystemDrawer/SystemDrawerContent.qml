import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.services
import "widgets"

Item {
    id: root

    implicitHeight: mainColumn.implicitHeight

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            id: mainColumn
            width: parent.width
            spacing: 16

            SystemDrawerHeader {
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderColor
                opacity: 0.35
            }

            SystemDrawerStats {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderColor
                opacity: 0.35
                visible: BatteryService.hasBattery
            }

            BatteryCard {
                Layout.fillWidth: true
                visible: BatteryService.hasBattery
            }
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderColor
                opacity: 0.35
            }

            SystemDrawerUpdates {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderColor
                opacity: 0.35
            }
            SystemDrawerAppearance {
                Layout.fillWidth: true
            }
        }
    }
}
