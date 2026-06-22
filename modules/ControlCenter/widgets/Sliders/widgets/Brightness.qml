import QtQuick
import qs.services
import qs.core

SliderRow {

    activeIcon: "󰃠"
    value: BrightnessService.percentage
    visible: BrightnessService.isAvailable

    onValueMoved: newValue => BrightnessService.setPercentage(newValue)
}
