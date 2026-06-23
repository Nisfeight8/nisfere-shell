import QtQuick

import qs.core
import qs.services

ControlButton {
    hasMore: true
    iconText: NetworkService.wifiEnabled ? "󰖩" : "󰖪"
    isActive: NetworkService.isWifiConnected
    subtitle: NetworkService.wifiName
    title: "Wi-Fi"
    visible: NetworkService.hasWifi

    onClicked: NetworkService.toggleWifi()
    onMoreClicked: pageStack.currentIndex = 1
}
