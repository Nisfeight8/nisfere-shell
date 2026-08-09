import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.services
import "widgets"

Item {
    id: root
    property var screen
    readonly property real uiScale: screen ? screen.height / 1080 : 1.0

    anchors.fill: parent

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 12

        SystemDrawerHeader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            uiScale: root.uiScale
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
            uiScale: root.uiScale
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
            Layout.fillHeight: true
            uiScale: root.uiScale
            visible: BatteryService.hasBattery
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
            uiScale: root.uiScale
        }
    }
}
