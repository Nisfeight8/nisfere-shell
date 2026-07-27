import QtQuick

import qs.core
import qs.services

ControlButton {
    hasMore: true
    // Was `isWifiConnecte` — typo, non-existent property (undefined),
    // matches `isWifiConnected` used correctly everywhere else (e.g.
    // InternalTrayWidget.qml).
    iconText: Icons.getWifiIcon(NetworkService.wifiEnabled, NetworkService.isWifiConnected, NetworkService.wifi.netStrength)
    isActive: NetworkService.isWifiConnected
    subtitle: NetworkService.wifiName
    title: "Wi-Fi"
    visible: NetworkService.hasWifi

    onClicked: NetworkService.wifi.toggle()
    // Was `pageStack.currentIndex = 1` — pageStack is ControlCenterContent.qml's
    // own root id, not visible here (this file is loaded dynamically,
    // several file/Loader boundaries away — same class of cross-file
    // scope bug we've hit repeatedly). ShellState is a global singleton,
    // reachable from anywhere, same pattern Dashboard/Productivity
    // already use for their own tab navigation
    // (currentDashboardTab/currentProductivityTab). Needs
    // ShellState.controlCenterPageIndex added — see chat.
    onMoreClicked: ShellState.controlCenterPageIndex = 1
}
