import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

BarWidget {
    id: audioWidget

    property bool popupOpened: false

    useGradient: true

    RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter
        LucideIcon {
            id: volumeIcon
            color: AudioService.muted ? Theme.color1 : Theme.selected
            size: 16
            icon: Icons.getVolumeIcon(AudioService.volume, AudioService.muted)

            Behavior on color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
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

            Behavior on color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }
        }

        Text {
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 14
            text: Math.round(AudioService.sourceVolume * 100) + "%"
        }
    }

    // Was a single MouseArea handling click (open popup) + wheel
    // (volume step) + cursor, reparented on top of the whole widget —
    // very likely swallowing clicks meant for the small mute-toggle
    // icon above (MouseArea hit-testing follows raw paint/z-order, and
    // this one painted on top of everything after reparenting). Split
    // into separate PointerHandlers: a TapHandler on a nested item
    // (the icon) gets first chance at a point before it propagates to
    // a shallower one, so the icon's own TapHandler can now actually
    // win instead of always losing to this one.
    HoverHandler {
        parent: audioWidget
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        parent: audioWidget
        onTapped: audioWidget.popupOpened = !audioWidget.popupOpened
    }
    // WheelHandler proved unreliable here in practice — falling back
    // to a plain MouseArea just for wheel scroll (acceptedButtons:
    // Qt.NoButton so it never competes with the TapHandler above for
    // clicks; MouseArea.onWheel is the mature, known-working API).
    MouseArea {
        parent: audioWidget
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        onWheel: wheel => {
            const step = 0.05;
            const delta = wheel.angleDelta.y > 0 ? step : -step;
            AudioService.setVolume(Math.max(0, Math.min(1, AudioService.volume + delta)));
        }
    }

    BarPopup {
        id: audioPopup

        showPopup: audioWidget.popupOpened
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
                        id: outputMuteIcon
                        color: AudioService.muted ? Theme.color1 : Theme.foreground
                        size: 16
                        icon: AudioService.muted ? "volume-x" : "volume-2"

                        Behavior on color {
                            AnimColor {
                                type: Anim.FastEffects
                            }
                        }

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: AudioService.toggleMute()
                        }
                    }
                    CustomSlider {
                        id: outputSlider
                        Layout.fillWidth: true

                        // Same fix as SliderRow.qml — a plain `value:`
                        // binding gets destroyed the first time the
                        // user drags, so this slider would stop
                        // following AudioService.volume if it ever
                        // changed externally (e.g. a hardware key).
                        Binding {
                            target: outputSlider
                            property: "value"
                            value: AudioService.volume
                            when: !outputSlider.pressed
                            restoreMode: Binding.RestoreNone
                        }

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

                            Behavior on color {
                                AnimColor {
                                    type: Anim.FastEffects
                                }
                            }

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                onTapped: AudioService.toggleSourceMute()
                            }
                        }
                    }
                    CustomSlider {
                        id: inputSlider
                        Layout.fillWidth: true

                        Binding {
                            target: inputSlider
                            property: "value"
                            value: AudioService.sourceVolume
                            when: !inputSlider.pressed
                            restoreMode: Binding.RestoreNone
                        }

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
