import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Rectangle {
    id: root

    property string container_id: ""
    property string container_name: ""
    property bool isOpen: false

    function close() {
        isOpen = false;
    }
    function open() {
        isOpen = true;
    }

    anchors.fill: parent
    border.color: Theme.borderColor
    border.width: Theme.widgetBorderWidth
    color: Theme.backgroundAlt
    radius: Theme.radius -2
    visible: isOpen

    Rectangle {
        id: modalBox

        anchors.centerIn: parent
        border.color: Theme.borderColor
        border.width: Theme.widgetBorderWidth
        color: Theme.background
        height: 180
        radius: Theme.radius - 2
        width: 340

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                Layout.fillWidth: true
                color: Theme.color1
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 14
                text: "Delete container?"
            }
            Text {
                Layout.fillWidth: true
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 11
                text: "Are you sure you want to delete\n<b>" + root.container_name + "</b>?"
                textFormat: Text.RichText
                wrapMode: Text.WordWrap
            }
            Item {
                Layout.fillHeight: true
            }

            // Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    border.color: Theme.borderColor
                    border.width: 1
                    color: Theme.backgroundAlt
                    height: 36
                    radius: 8

                    Text {
                        anchors.centerIn: parent
                        color: Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 11
                        text: "Cancel"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: root.close()
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    border.color: Theme.color1
                    border.width: 1
                    color: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.15)
                    height: 36
                    radius: 8

                    Text {
                        anchors.centerIn: parent
                        color: Theme.color1
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 11
                        text: "Delete"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            DockerService.containerAction("delete", root.container_id);
                            root.close();
                        }
                    }
                }
            }
        }
    }
}
