import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Bluetooth
import qs.core
import qs.services

Item {
    id: root
    property real uiScale: 1.0

    signal backRequested

    implicitHeight: mainColumn.implicitHeight

    ColumnLayout {
        id: mainColumn
        width: parent.width
        spacing: 20 * root.uiScale

        // ── Header ───────────────────────────────────────────────
        PageHeader {
            Layout.fillWidth: true
            title: "Bluetooth Settings"
            uiScale: root.uiScale
            onBackRequested: root.backRequested()

            ToggleSwitch {
                checked: BluetoothService.isEnabled
                uiScale: root.uiScale
                onToggled: BluetoothService.toggle()
            }
        }
        // Sub-header + Scan button
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 5 * root.uiScale

            SectionLabel {
                Layout.fillWidth: true
                text: "Available & Saved Devices"
                uiScale: root.uiScale
            }

            NavTile {
                Layout.preferredWidth: 90 * root.uiScale
                Layout.preferredHeight: 28 * root.uiScale
                icon: BluetoothService.isScanning ? "refresh-cw" : "search"
                label: BluetoothService.isScanning ? "Scan..." : "Scan"
                isActive: BluetoothService.isScanning
                activeColor: Theme.color1
                uiScale: root.uiScale
                onTapped: BluetoothService.toggleScan()
            }
        }
        DisabledStateCard {
            Layout.fillWidth: true
            implicitHeight: 150 * root.uiScale
            visible: BluetoothService.isEnabled && Bluetooth.devices.values.length < 1
            icon: "bluetooth"
            message: "Scan to find available devices"
        }
        // ── Device List (BT ON) ───────────────────────────────────
        CustomScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(devicesColumn.implicitHeight, 400 * root.uiScale)
            uiScale: root.uiScale
            visible: BluetoothService.isEnabled && Bluetooth.devices.values.length > 0

            ColumnLayout {
                id: devicesColumn
                spacing: 10 * root.uiScale
                width: scrollView.width

                Repeater {
                    model: Bluetooth.devices.values

                    delegate: GlassCard {
                        Layout.fillWidth: true
                        implicitHeight: 60 * root.uiScale

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15 * root.uiScale
                            spacing: 15 * root.uiScale

                            LucideIcon {
                                color: model.connected ? Theme.selected : Theme.foreground
                                size: 20 * root.uiScale
                                icon: model.batteryAvailable ? "headphones" : "bluetooth"

                                Behavior on color {
                                    AnimColor {
                                        type: Anim.FastEffects
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2 * root.uiScale

                                Text {
                                    Layout.fillWidth: true
                                    color: Theme.foreground
                                    elide: Text.ElideRight
                                    font.bold: true
                                    font.pixelSize: 13 * root.uiScale
                                    text: model.name !== "" ? model.name : model.deviceName
                                }

                                RowLayout {
                                    spacing: 8 * root.uiScale

                                    Text {
                                        color: model.connected ? Theme.selected : Theme.foreground
                                        font.pixelSize: 11 * root.uiScale
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

                                        Behavior on color {
                                            AnimColor {
                                                type: Anim.FastEffects
                                            }
                                        }
                                    }

                                    Row {
                                        Layout.alignment: Qt.AlignVCenter
                                        visible: model.batteryAvailable && model.connected
                                        spacing: 4 * root.uiScale
                                        opacity: 0.8

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: Theme.foreground
                                            font.pixelSize: 11 * root.uiScale
                                            text: "•  " + Math.round(model.battery * 100) + "%"
                                        }

                                        LucideIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: Theme.foreground
                                            size: 14 * root.uiScale
                                            icon: Icons.getBatteryIcon(model.battery * 100, false)
                                        }
                                    }
                                }
                            }

                            IconButton {
                                size: 32 * root.uiScale
                                iconSize: 16 * root.uiScale
                                hoverSolid: true
                                alwaysBorder: true
                                borderColor: model.connected ? Theme.color1 : Theme.selected
                                contrastColor: Theme.background
                                hoverColor: model.connected ? Theme.color1 : Theme.selected
                                tooltipText: {
                                    if (model.connected)
                                        return "Disconnect";
                                    if (model.paired)
                                        return "Trust";
                                    return "Connect";
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
            implicitHeight: 150 * root.uiScale
            visible: !BluetoothService.isEnabled
            icon: "bluetooth-off"
            message: "Bluetooth is turned off"
        }
    }
}
