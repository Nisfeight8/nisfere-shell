import QtQuick
import QtQuick.Layouts

import qs.core
import qs.services

GlassCard {
    id: systemInfoDetailsMini

    property real refSize: 120

    Layout.fillHeight: true
    Layout.fillWidth: true

    GridLayout {
        anchors.centerIn: parent
        columnSpacing: Math.max(10, systemInfoDetailsMini.refSize * 0.10)
        columns: 2
        rowSpacing: Math.max(15, systemInfoDetailsMini.refSize * 0.15)
        width: parent.width * 0.9

        InfoItem {
            iconName: "user"
            titleText: "User"
            valueText: SystemInfo.username
        }
        InfoItem {
            iconName: "shell"
            titleText: "OS"
            valueText: SystemInfo.osName
        }
        InfoItem {
            iconName: "layout-template"
            titleText: "WM"
            valueText: SystemInfo.windowManager
        }
        InfoItem {
            iconName: "clock"
            titleText: "Uptime"
            valueText: SystemInfo.uptime
        }
    }

    component InfoItem: RowLayout {
        property color iconColor: Theme.selected
        property string iconName
        property string titleText
        property string valueText

        Layout.fillWidth: true
        spacing: Math.max(6, systemInfoDetailsMini.refSize * 0.08)

        LucideIcon {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            color: iconColor
            size: Math.max(16, systemInfoDetailsMini.refSize * 0.18)
            icon: iconName
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: 2

            Text {
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: Math.max(9, systemInfoDetailsMini.refSize * 0.08)
                opacity: 0.5
                text: titleText.toUpperCase()
            }
            Text {
                Layout.fillWidth: true
                color: Theme.foreground
                elide: Text.ElideRight
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: Math.max(11, systemInfoDetailsMini.refSize * 0.12)
                text: valueText
            }
        }
    }
}
