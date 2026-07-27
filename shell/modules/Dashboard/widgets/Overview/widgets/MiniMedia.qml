import QtQuick
import QtQuick.Layouts

import qs.core
import qs.services

GlassCard {
    id: miniMedia

    property real refSize: 120

    implicitWidth: mainLayout.implicitWidth + mainLayout.anchors.margins * 2
    implicitHeight: mainLayout.implicitHeight + mainLayout.anchors.margins * 2

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: Math.max(10, miniMedia.refSize * 0.1)
        spacing: Math.max(10, miniMedia.refSize * 0.1)

        // ── Album art ─────────────────────────────────────────────
        Rectangle {
            readonly property real artSize: Math.max(60, miniMedia.refSize * 0.8)
            Layout.preferredWidth: artSize
            Layout.preferredHeight: artSize
            clip: true
            color: Theme.background
            radius: Theme.radius - 4

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: MediaService.albumArt
                visible: MediaService.albumArt !== ""
            }
            LucideIcon {
                anchors.centerIn: parent
                icon: "music"
                size: Math.max(24, parent.width * 0.4)
                color: Theme.foreground
                opacity: 0.5
                visible: MediaService.albumArt === ""
            }
        }

        // ── Info + controls ───────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: MediaService.title
                color: Theme.foreground
                elide: Text.ElideRight
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: Math.max(14, miniMedia.refSize * 0.15)
            }
            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: MediaService.artist !== "" ? MediaService.artist : "Unknown Artist"
                color: Theme.foreground
                elide: Text.ElideRight
                font.family: Theme.fontName
                font.pixelSize: Math.max(11, miniMedia.refSize * 0.12)
                opacity: 0.7
            }

            Item {
                Layout.fillHeight: true
            }

            MediaSlider {
                id: miniMediaSlider
                Layout.fillWidth: true
                trackColor: Theme.background
            }

            // ── Transport controls ────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                IconButton {
                    icon: "skip-back"
                    flat: true
                    size: Math.max(18, miniMedia.refSize * 0.18)
                    iconSize: Math.max(18, miniMedia.refSize * 0.18)
                    fixedIconColor: Theme.foreground
                    idleOpacity: 0.7
                    onTapped: MediaService.previous()
                }

                IconButton {
                    id: playBtn
                    icon: MediaService.isPlaying ? "pause" : "play"
                    flat: true
                    size: Math.max(20, miniMedia.refSize * 0.20)
                    iconSize: Math.max(20, miniMedia.refSize * 0.20)
                    fixedIconColor: Theme.selected
                    dimWhenIdle: false   // always full opacity — this is the primary action
                    scale: pressed ? 0.9 : 1.0
                    
                    Behavior on scale {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }
                    onTapped: MediaService.togglePlayPause()
                }

                IconButton {
                    icon: "skip-forward"
                    flat: true
                    size: Math.max(18, miniMedia.refSize * 0.18)
                    iconSize: Math.max(18, miniMedia.refSize * 0.18)
                    fixedIconColor: Theme.foreground
                    idleOpacity: 0.7
                    onTapped: MediaService.next()
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
