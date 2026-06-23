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
    onLiveValueMoved: newValue => AudioService.setSourceVolume(newValue)
}
