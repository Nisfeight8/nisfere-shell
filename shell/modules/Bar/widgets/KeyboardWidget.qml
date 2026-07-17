import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

BarWidget {
    id: kbWidget

    bgColor: "transparent"

    RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter
        LucideIcon {
            size: 16
            color: Theme.selected
            icon: "keyboard"
        }
        Text {
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 14
            text: KeyboardService.getShort(KeyboardService.currentLayout)
        }
    }

    MouseArea {
        id: kbMouseArea

        property bool popupOpened: false

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        parent: kbWidget

        onClicked: popupOpened = !popupOpened
    }

    BarPopup {
        id: kbPopup

        showPopup: kbMouseArea.popupOpened
        targetItem: kbWidget

        ColumnLayout {
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                LucideIcon {
                    size: 20
                    color: Theme.selected
                    icon: "keyboard"
                }
                Text {
                    Layout.fillWidth: true
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    text: "Keyboard Layout"
                }
            }
            Rectangle {
                Layout.fillWidth: true
                color: Theme.backgroundAlt
                height: 1
                opacity: 0.8
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: KeyboardService.availableLayouts

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        color: itemMouseArea.containsMouse ? Theme.backgroundAlt : "transparent"
                        radius: 6

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            
                            Text {
                                Layout.fillWidth: true
                                color: KeyboardService.getShort(KeyboardService.currentLayout) === KeyboardService.getShort(modelData.toLowerCase()) ? Theme.selected : Theme.foreground
                                font.bold: KeyboardService.getShort(KeyboardService.currentLayout) === KeyboardService.getShort(modelData.toLowerCase())
                                font.family: Theme.fontName
                                font.pixelSize: 13
                                text: KeyboardService.getFull(modelData)
                            }
                            LucideIcon {
                                color: Theme.selected
                                size: 14
                                icon: "check"
                                visible: KeyboardService.getShort(KeyboardService.currentLayout) === KeyboardService.getShort(modelData.toLowerCase())
                            }
                        }
                        MouseArea {
                            id: itemMouseArea

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: {
                                KeyboardService.changeLayout(index);
                                kbMouseArea.popupOpened = false;
                            }
                        }
                    }
                }
            }
            Item {
                Layout.fillHeight: true
            }
        }
    }
}
