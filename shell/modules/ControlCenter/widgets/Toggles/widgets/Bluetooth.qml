import QtQuick
import qs.core
import qs.services

ControlButton {
    hasMore: true
    iconText: Icons.getBuetoothIcon(BluetoothService.isEnabled, BluetoothService.connectedDevicesCount > 0)
    isActive: BluetoothService.isEnabled
    subtitle: BluetoothService.statusName
    title: "Bluetooth"
    visible: BluetoothService.hasBluetooth

    onClicked: BluetoothService.toggle()
    onMoreClicked: pageStack.currentIndex = 2
}
