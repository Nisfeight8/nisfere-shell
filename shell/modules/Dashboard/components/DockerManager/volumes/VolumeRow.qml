import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    property real uiScale: 1.0
    required property var vol // {name, driver, mountpoint}

    signal deleteRequested(string volName, string volLabel)

    border.color: Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.40)
    border.width: 1
    color: Theme.backgroundAlt
    height: 42 * root.uiScale
    radius: Theme.radius
    width: parent.width

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10 * root.uiScale
        anchors.rightMargin: 10 * root.uiScale
        spacing: 8 * root.uiScale

        LucideIcon {
            icon: "database"
            size: 14 * root.uiScale
            color: Theme.color6
        }

        Column {
            Layout.fillWidth: true
            spacing: 1 * root.uiScale

            Text {
                width: parent.width
                color: Theme.foreground
                elide: Text.ElideRight
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 12 * root.uiScale
                text: root.vol.name
            }
            Text {
                width: parent.width
                color: Theme.foregroundAlt
                elide: Text.ElideMiddle
                font.family: Theme.fontName
                font.pixelSize: 10 * root.uiScale
                text: root.vol.driver + " · " + (root.vol.mountpoint || "—")
            }
        }

        IconButton {
            icon: "x"
            size: 22 * root.uiScale
            iconSize: 12 * root.uiScale
            normalColor: Qt.rgba(Theme.color9.r, Theme.color9.g, Theme.color9.b, 0.10)
            hoverColor: Theme.color9
            fixedIconColor: Theme.color9
            tooltipText: "Delete"
            onTapped: root.deleteRequested(root.vol.name, root.vol.name)
        }
    }
}
