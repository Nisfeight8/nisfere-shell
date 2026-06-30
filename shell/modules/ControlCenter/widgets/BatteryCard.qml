import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.core
import qs.services

GlassCard {
    id: batteryCard

    Layout.fillWidth: true
    implicitHeight: batteryRow.implicitHeight + 30

    visible: BatteryService.hasBattery

    

    RowLayout {
        id: batteryRow

        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        LucideIcon {
            Layout.alignment: Qt.AlignVCenter
            color: (BatteryService.percentage <= 20 && !BatteryService.isCharging) ? Theme.color1 : Theme.selected
            size: 34
            icon: Icons.getBatteryIcon(BatteryService.percentage, BatteryService.isCharging)
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    color: Theme.foreground
                    font.bold: true
                    font.pixelSize: 14
                    text: "Battery"
                }
                Text {
                    color: Theme.foreground
                    font.bold: true
                    font.pixelSize: 14
                    text: BatteryService.percentage + "%"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                color: Theme.background
                height: 6
                radius: 3

                Rectangle {
                    color: (BatteryService.percentage <= 20 && !BatteryService.isCharging) ? Theme.color1 : Theme.selected
                    height: parent.height
                    radius: 3
                    width: parent.width * (BatteryService.percentage / 100)

                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Text {
                color: Theme.foreground
                font.pixelSize: 11
                opacity: 0.6
                text: BatteryService.timeText
            }
        }
    }
}
