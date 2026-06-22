import QtQuick
import qs.core
import qs.services

ControlButton {
    hasMore: true
    iconText: {
        if (!BluetoothService.isEnabled)
            return "󰂲";
        if (BluetoothService.connectedDevicesCount > 0)
            return "󰂱";
        return "󰂯";
    }
    isActive: BluetoothService.isEnabled
    subtitle: BluetoothService.statusName
    title: "Bluetooth"
    visible: BluetoothService.hasBluetooth

    onClicked: BluetoothService.toggle()
    onMoreClicked: pageStack.currentIndex = 2
}
