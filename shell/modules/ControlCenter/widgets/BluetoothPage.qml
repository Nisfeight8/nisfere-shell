import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Bluetooth

import qs.core
import qs.services

Item {
    id: root

    signal backRequested

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 15

            Rectangle {
                border.color: Theme.borderColor
                border.width: 1
                color: backMouse.containsMouse ? Theme.backgroundAlt : "transparent"
                height: 36
                radius: 18
                width: 36

                LucideIcon {
                    anchors.centerIn: parent
                    color: Theme.foreground
                    size: 18
                    icon: "arrow-left"
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.backRequested()
                }
            }
            Text {
                Layout.fillWidth: true
                color: Theme.foreground
                font.bold: true
                font.pixelSize: 20
                text: "Bluetooth Settings"
            }
            Rectangle {
                border.color: Theme.borderColor
                border.width: BluetoothService.isEnabled ? 0 : 1
                color: BluetoothService.isEnabled ? Theme.selected : Theme.backgroundAlt
                height: 24
                radius: 12
                width: 44

                Rectangle {
                    color: Theme.foreground
                    height: 18
                    radius: 9
                    width: 18
                    x: BluetoothService.isEnabled ? 23 : 3
                    y: 3

                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothService.toggle()
                }
            }
        }

        ScrollView {
            id: scrollView
            Layout.fillHeight: true
            Layout.fillWidth: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            clip: true
            visible: BluetoothService.isEnabled

            ColumnLayout {
                spacing: 10
                width: scrollView.availableWidth

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 5

                    Text {
                        Layout.fillWidth: true
                        color: Theme.foreground
                        font.bold: true
                        opacity: 0.7
                        text: "Available & Saved Devices"
                    }

                    // Scan Button
                    Rectangle {
                        color: BluetoothService.isScanning ? Theme.color1 : Theme.backgroundAlt
                        height: 28
                        radius: 14
                        width: 90

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            LucideIcon {
                                color: BluetoothService.isScanning ? Theme.background : Theme.foreground
                                size: 12
                                icon: BluetoothService.isScanning ? "refresh-cw" : "search"
                            }

                            Text {
                                color: BluetoothService.isScanning ? Theme.background : Theme.foreground
                                font.pixelSize: 12
                                text: BluetoothService.isScanning ? "Scan..." : "Scan"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BluetoothService.toggleScan()
                        }
                    }
                }

                Repeater {
                    model: Bluetooth.devices.values

                    delegate: GlassCard {
                        Layout.fillWidth: true
                        implicitHeight: 60

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 15

                            LucideIcon {
                                color: model.connected ? Theme.selected : Theme.foreground
                                size: 20
                                icon: model.batteryAvailable ? "headphones" : "bluetooth"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    color: Theme.foreground
                                    elide: Text.ElideRight
                                    font.bold: true
                                    text: model.name !== "" ? model.name : model.deviceName
                                }
                                RowLayout {
                                    spacing: 8

                                    Text {
                                        color: model.connected ? Theme.selected : Theme.foreground
                                        font.pixelSize: 11
                                        opacity: model.connected ? 1.0 : 0.6
                                        text: {
                                            if (model.connected)
                                                return "Connected";
                                            if (model.pairing)
                                                return "Pairing...";
                                            if (model.paired)
                                                return "Saved";
                                            return "Available";
                                        }
                                    }

                                    Row {
                                        Layout.alignment: Qt.AlignVCenter
                                        visible: model.batteryAvailable && model.connected
                                        spacing: 4
                                        opacity: 0.8

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: Theme.foreground
                                            font.pixelSize: 11
                                            text: "•  " + Math.round(model.battery * 100) + "%"
                                        }
                                        LucideIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: Theme.foreground
                                            size: 14
                                            icon: Icons.getBatteryIcon(model.battery * 100, false)
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                color: {
                                    if (!btnMouse.containsMouse) {
                                        return (model.connected) ? Theme.color1 : Theme.backgroundAlt;
                                    }
                                    return Theme.selected;
                                }
                                height: 36
                                radius: 18
                                width: 36
                                opacity: model.pairing ? 0.5 : 1.0
                                border.width: 1
                                border.color: Theme.borderColor

                                LucideIcon {
                                    anchors.centerIn: parent
                                    color: {
                                        if (btnMouse.containsMouse) {
                                            return Theme.backgroundAlt;
                                        } else {
                                            if (model.connected)
                                                return Theme.foreground;
                                            return Theme.selected;
                                        }
                                    }
                                    size: 16
                                    icon: model.pairing ? "refresh-cw" : (model.connected ? "x" : "check")
                                }

                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !model.pairing
                                    onClicked: {
                                        if (model.connected) {
                                            modelData.connected = false;
                                        } else if (model.paired) {
                                            modelData.trusted = true;
                                            modelData.connected = true;
                                        } else {
                                            modelData.connected = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            visible: !BluetoothService.isEnabled

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 15

                LucideIcon {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.foreground
                    size: 64
                    opacity: 0.3
                    icon: "bluetooth-off"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.foreground
                    font.pixelSize: 16
                    opacity: 0.6
                    text: "Bluetooth is turned off"
                }
            }
        }
    }
}
