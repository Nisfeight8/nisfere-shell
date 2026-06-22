import QtQuick

import qs.core
import qs.services

ControlButton {
    iconText: NetworkService.wifiEnabled ? "󰖩" : "󰖪"
    isActive: NetworkService.isWifiConnected
    subtitle: NetworkService.wifiName
    title: "Wi-Fi"
    visible: NetworkService.hasWifi

    onClicked: NetworkService.toggleWifi()
}
