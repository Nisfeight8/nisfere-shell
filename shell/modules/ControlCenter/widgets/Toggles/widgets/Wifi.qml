import QtQuick

import qs.core
import qs.services

ControlButton {
    hasMore: true
    iconText: Icons.getWifiIcon(NetworkService.wifiEnabled, NetworkService.isWifiConnecte, NetworkService.wifi.netStrength)
    isActive: NetworkService.isWifiConnected
    subtitle: NetworkService.wifiName
    title: "Wi-Fi"
    visible: NetworkService.hasWifi

    onClicked: NetworkService.toggleWifi()
    onMoreClicked: pageStack.currentIndex = 1
}
