import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.core
import qs.services
import Quickshell.Bluetooth

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

                Text {
                    anchors.centerIn: parent
                    color: Theme.foreground
                    font.pixelSize: 18
                    text: "󰁍"
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
            Layout.fillHeight: true
            Layout.fillWidth: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            clip: true
            visible: BluetoothService.isEnabled

            ColumnLayout {
                spacing: 10
                width: parent.width

                Text {
                    Layout.bottomMargin: 5
                    color: Theme.foreground
                    font.bold: true
                    opacity: 0.7
                    text: "Available & Saved Devices"
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

                            Text {
                                color: model.connected ? Theme.selected : Theme.foreground
                                font.pixelSize: 20
                                text: model.batteryAvailable ? "󰋋" : "󰂯"
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
                                    Text {
                                        color: Theme.foreground
                                        font.pixelSize: 11
                                        opacity: 0.8
                                        text: "•  " + Math.round(model.battery * 100) + "% 󰁹"
                                        visible: model.batteryAvailable && model.connected
                                    }
                                }
                            }
                            Rectangle {
                                color: model.connected ? Theme.color1 : Theme.backgroundAlt
                                height: 36
                                radius: 18
                                width: 36

                                Text {
                                    anchors.centerIn: parent
                                    color: model.connected ? Theme.background : Theme.foreground
                                    font.pixelSize: 16
                                    text: model.connected ? "󰅖" : "󰄬"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        if (model.connected) {
                                            model.disconnect();
                                        } else if (model.paired) {
                                            model.connect();
                                        } else {
                                            model.pair();
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

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.foreground
                    font.pixelSize: 64
                    opacity: 0.3
                    text: "󰂲"
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
