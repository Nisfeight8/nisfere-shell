import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

GlassCard {
    id: systemInfoDetailsMini

    // Same missing piece as the other two cards — without this the
    // Loader's Layout.fillWidth/fillHeight in Overview.qml has
    // nothing to stretch.
    anchors.fill: parent

    // Was a fixed magic constant (120) — same fix as the other three
    // cards: derive from the card's actual rendered size.
    readonly property real refSize: Math.min(systemInfoDetailsMini.width, systemInfoDetailsMini.height)

    // Previous implicitWidth/implicitHeight (computed from gridLayout)
    // removed — dead now that anchors.fill above determines the
    // actual size, same reasoning as the other three cards.

    GridLayout {
        id: gridLayout

        anchors.fill: parent
        anchors.margins: 15
        columnSpacing: Math.max(10, systemInfoDetailsMini.refSize * 0.10)
        columns: 2
        rowSpacing: Math.max(15, systemInfoDetailsMini.refSize * 0.15)

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
                Layout.preferredWidth: 0
                font.family: Theme.fontName
                font.pixelSize: Math.max(9, systemInfoDetailsMini.refSize * 0.08)
                opacity: 0.5
                text: titleText.toUpperCase()
            }
            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
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
