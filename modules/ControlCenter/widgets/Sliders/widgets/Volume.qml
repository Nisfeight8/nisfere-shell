import QtQuick
import qs.services
import qs.core

SliderRow {
    activeIcon: AudioService.volume > 0.5 ? "󰕾" : (AudioService.volume > 0 ? "󰖀" : "󰕿")
    isMuteable: true
    isMuted: AudioService.muted
    mutedIcon: "󰝟"
    value: AudioService.volume

    onToggleMuteClicked: AudioService.toggleMute()
    onValueMoved: newValue => AudioService.setVolume(newValue)
}
