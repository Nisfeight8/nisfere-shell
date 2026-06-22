import QtQuick
import qs.core
import qs.services

ControlButton {
    hasMore: true
    iconText: "󰈀"
    isActive: NetworkService.isEthernetConnected
    subtitle: NetworkService.ethernetName
    title: "Ethernet"
    visible: NetworkService.hasEthernet

    onClicked: NetworkService.ethernet.toggle()
    onMoreClicked: pageStack.currentIndex = 3
}
