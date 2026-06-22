import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services

BarWidget {
    id: audioWidget

    useGradient: true

    Row {
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: AudioService.muted ? Theme.color1 : Theme.selected
            font.family: Theme.fontName
            font.pixelSize: 16
            text: {
                if (AudioService.muted)
                    return "󰝟";
                if (AudioService.volume < 0.33)
                    return "󰕿";
                if (AudioService.volume < 0.66)
                    return "󰖀";
                return "󰕾";
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 13
            text: Math.round(AudioService.volume * 100) + "%"
        }
    }
    Row {
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: AudioService.sourceMuted ? Theme.color1 : Theme.selected
            font.family: Theme.fontName
            font.pixelSize: 16
            text: AudioService.sourceMuted ? "󰍭" : "󰍬"
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 13
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

                Text {
                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: 18
                    text: "󰕾"
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

                    Text {
                        color: AudioService.muted ? Theme.color1 : Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 16
                        text: AudioService.muted ? "󰝟" : "󰕾"

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

                    Text {
                        color: AudioService.sourceMuted ? Theme.color1 : Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 16
                        text: AudioService.sourceMuted ? "󰍭" : "󰍬"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: AudioService.toggleSourceMute()
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
