import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.core
import qs.services

GlassCard {
    id: miniMedia

    readonly property real refSize: Math.min(width, height)

    Layout.fillHeight: true
    Layout.fillWidth: true

    RowLayout {
        anchors.fill: parent
        anchors.margins: Math.max(10, miniMedia.refSize * 0.1)
        spacing: Math.max(10, miniMedia.refSize * 0.1)

        Rectangle {
            readonly property real artSize: Math.max(60, miniMedia.refSize * 0.8)

            Layout.preferredHeight: artSize
            Layout.preferredWidth: artSize
            clip: true
            color: Theme.background
            radius: Theme.radius - 4

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: MediaService.albumArt
                visible: MediaService.albumArt !== ""
            }
            Text {
                anchors.centerIn: parent
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: Math.max(24, parent.width * 0.4)
                opacity: 0.5
                text: "󰝚"
                visible: MediaService.albumArt === ""
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                color: Theme.foreground
                elide: Text.ElideRight
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: Math.max(14, miniMedia.refSize * 0.15)
                text: MediaService.title
            }
            Text {
                Layout.fillWidth: true
                color: Theme.foreground
                elide: Text.ElideRight
                font.family: Theme.fontName
                font.pixelSize: Math.max(11, miniMedia.refSize * 0.12)
                opacity: 0.7
                text: MediaService.artist !== "" ? MediaService.artist : "Unknown Artist"
            }
            Item {
                Layout.fillHeight: true
            }
            MediaSlider {
                id: miniMediaSlider
                trackColor: Theme.background
                Layout.fillWidth: true
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                Text {
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(18, miniMedia.refSize * 0.18)
                    opacity: mediaMouseAreaPrev.containsMouse ? 1.0 : 0.7
                    text: "󰒮"

                    MouseArea {
                        id: mediaMouseAreaPrev

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: MediaService.previous()
                    }
                }
                Text {
                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(24, miniMedia.refSize * 0.24)
                    scale: mediaMouseAreaPlay.pressed ? 0.9 : 1.0
                    text: MediaService.isPlaying ? "󰏤" : "󰐊"

                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                        }
                    }

                    MouseArea {
                        id: mediaMouseAreaPlay

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: MediaService.togglePlayPause()
                    }
                }
                Text {
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(18, miniMedia.refSize * 0.18)
                    opacity: mediaMouseAreaNext.containsMouse ? 1.0 : 0.7
                    text: "󰒭"

                    MouseArea {
                        id: mediaMouseAreaNext

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: MediaService.next()
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
