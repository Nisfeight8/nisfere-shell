import QtQuick
import qs.services
import qs.core

SliderRow {
    activeIcon: "󰍬"
    isMuteable: true
    isMuted: AudioService.sourceMuted
    mutedIcon: "󰍭"
    value: AudioService.sourceVolume

    onToggleMuteClicked: AudioService.toggleSourceMute()
    onValueMoved: newValue => AudioService.setSourceVolume(newValue)
}
