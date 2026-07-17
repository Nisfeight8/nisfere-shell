import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Bluetooth
import qs.core
import qs.services

Item {
    id: root

    signal backRequested

    implicitHeight: mainColumn.implicitHeight

    ColumnLayout {
        id: mainColumn
        width: parent.width
        spacing: 20

        // ── Header ───────────────────────────────────────────────
        PageHeader {
            Layout.fillWidth: true
            title: "Bluetooth Settings"
            onBackRequested: root.backRequested()

            ToggleSwitch {
                checked: BluetoothService.isEnabled
                onToggled: BluetoothService.toggle()
            }
        }
        // Sub-header + Scan button
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 5

            SectionLabel {
                Layout.fillWidth: true
                title: "Available & Saved Devices"
            }

            NavTile {
                Layout.preferredWidth: 90
                Layout.preferredHeight: 28
                icon: BluetoothService.isScanning ? "refresh-cw" : "search"
                label: BluetoothService.isScanning ? "Scan..." : "Scan"
                isActive: BluetoothService.isScanning
                activeColor: Theme.color1
                onTapped: BluetoothService.toggleScan()
            }
        }
        DisabledStateCard {
            Layout.fillWidth: true
            implicitHeight: 150
            visible: BluetoothService.isEnabled && Bluetooth.devices.values.length < 1
            icon: "bluetooth"
            message: "Scan to find available devices"
        }
        // ── Device List (BT ON) ───────────────────────────────────
        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(devicesColumn.implicitHeight, 400)
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            clip: true
            visible: BluetoothService.isEnabled && Bluetooth.devices.values.length > 0

            ColumnLayout {
                id: devicesColumn
                spacing: 10
                width: scrollView.availableWidth

                // Device cards
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

                            // Connect/Disconnect/Pairing button — fits
                            // IconButton cleanly: isActive=connected (solid
                            // color1), hoverSolid=selected, spinning=pairing.
                            IconButton {
                                hoverSolid: true
                                alwaysBorder: true
                                borderColor: model.connected ? Theme.color1 : Theme.selected
                                contrastColor: Theme.background
                                hoverColor: model.connected ? Theme.color1 : Theme.selected
                                tooltipText: {
                                    if (model.connected)
                                        "Disconnect";
                                    else if (model.paired) {
                                        "Trust";
                                    } else {
                                        "Connect";
                                    }
                                }
                                icon: model.pairing ? "refresh-cw" : (model.connected ? "x" : "check")

                                onTapped: {
                                    if (model.connected)
                                        modelData.connected = false;
                                    else if (model.paired) {
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

        // ── BT Off State ───────────────────────────────────────────
        DisabledStateCard {
            Layout.fillWidth: true
            implicitHeight: 150
            visible: !BluetoothService.isEnabled
            icon: "bluetooth-off"
            message: "Bluetooth is turned off"
        }
    }
}
