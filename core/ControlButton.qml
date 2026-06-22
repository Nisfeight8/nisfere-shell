import QtQuick
import QtQuick.Layouts
import qs.core

GlassCard {
    id: root

    property bool hasMore: false
    property string iconText: "?"
    property bool isActive: false
    property string subtitle: "Subtitle"
    property string title: "Title"

    signal clicked
    signal moreClicked

    Layout.fillWidth: true
    Layout.preferredHeight: 70

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
    }
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
            border.color: root.isActive ? "transparent" : Theme.borderColor
            border.width: root.isActive ? 0 : 1
            color: root.isActive ? Theme.selected : "transparent"
            height: 40
            radius: 20
            width: 40

            Text {
                anchors.centerIn: parent
                color: root.isActive ? Theme.background : Theme.foreground
                font.pixelSize: 18
                text: root.iconText
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                color: Theme.foreground
                elide: Text.ElideRight
                font.bold: true
                font.pixelSize: 14
                text: root.title
            }
            Text {
                Layout.fillWidth: true
                color: Theme.foreground
                elide: Text.ElideRight
                font.pixelSize: 11
                opacity: 0.6
                text: root.subtitle
            }
        }
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            color: moreMouseArea.containsMouse ? Theme.background : "transparent"
            height: 30
            radius: 15
            visible: root.hasMore
            width: 30

            Text {
                anchors.centerIn: parent
                color: Theme.foreground
                font.pixelSize: 22
                opacity: 0.7
                text: "󰅂"
            }
            MouseArea {
                id: moreMouseArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: mouse => {
                    mouse.accepted = true;
                    root.moreClicked();
                }
            }
        }
    }
}
