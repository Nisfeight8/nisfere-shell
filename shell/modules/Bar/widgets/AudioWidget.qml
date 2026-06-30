import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

BarWidget {
    id: audioWidget

    useGradient: true

    RowLayout {
        spacing: 6
        // Εδώ το verticalAlignment δουλεύει κανονικά
        Layout.alignment: Qt.AlignVCenter
        LucideIcon {
            color: AudioService.muted ? Theme.color1 : Theme.selected
            size: 16
            icon: Icons.getVolumeIcon(AudioService.volume, AudioService.muted)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: AudioService.toggleMute()
            }
        }
        Text {
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 14
            text: Math.round(AudioService.volume * 100) + "%"
        }
    }
    RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter

        LucideIcon {

            color: AudioService.sourceMuted ? Theme.color1 : Theme.selected
            size: 16
            icon: Icons.getMicIcon(AudioService.sourceMuted)
        }

        Text {
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 14
            text: Math.round(AudioService.sourceVolume * 100) + "%"
        }
    }
    MouseArea {
        id: audioMouseArea

        property bool popupOpened: false

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        parent: audioWidget

        onClicked: popupOpened = !popupOpened
        onWheel: wheel => {
            let step = 0.05;
            if (wheel.angleDelta.y > 0)
                AudioService.setVolume(AudioService.volume + step);
            else
                AudioService.setVolume(AudioService.volume - step);
        }
    }
    BarPopup {
        id: audioPopup

        showPopup: audioMouseArea.popupOpened
        targetItem: audioWidget

        ColumnLayout {
            implicitWidth: 260
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                LucideIcon {
                    color: Theme.selected
                    size: 20
                    icon: "book-headphones"
                }
                Text {
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    text: "Audio Settings"
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

                Text {
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 10
                    opacity: 0.5
                    text: "OUTPUT DEVICE"
                }
                RowLayout {
                    spacing: 10

                    LucideIcon {
                        color: AudioService.muted ? Theme.color1 : Theme.foreground
                        size: 16
                        icon: AudioService.muted ? "volume-x" : "volume-2"
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.toggleMute()
                        }
                    }
                    CustomSlider {
                        Layout.fillWidth: true
                        value: AudioService.volume

                        onMoved: AudioService.setVolume(value)
                    }
                    Text {
                        Layout.preferredWidth: 35
                        color: Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(AudioService.volume * 100) + "%"
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 10
                    opacity: 0.5
                    text: "INPUT DEVICE"
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    RowLayout {
                        spacing: 6

                        LucideIcon {
                            Layout.alignment: Qt.AlignVCenter

                            color: AudioService.sourceMuted ? Theme.color1 : Theme.foreground
                            size: 16

                            icon: Icons.getMicIcon(AudioService.sourceMuted)

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AudioService.toggleSourceMute()
                            }
                        }

                    }
                    CustomSlider {
                        Layout.fillWidth: true
                        value: AudioService.sourceVolume

                        onMoved: AudioService.setSourceVolume(value)
                    }
                    Text {
                        color: Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(AudioService.sourceVolume * 100) + "%"
                    }
                }
            }
            Item {
                Layout.fillHeight: true
            }
        }
    }
}
