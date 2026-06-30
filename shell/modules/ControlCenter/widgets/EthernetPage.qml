import QtQuick
import QtQuick.Layouts

import qs.core
import qs.services

Item {
    id: root

    property var ethDevice: NetworkService.ethernet.device

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
                    icon: "arrow-left"
                    size: 16
                    color: Theme.foreground
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
                text: "Ethernet Settings"
            }
        }
        GlassCard {
            Layout.fillWidth: true
            implicitHeight: infoLayout.implicitHeight + 30

            ColumnLayout {
                id: infoLayout

                anchors.fill: parent
                anchors.margins: 15
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        color: Theme.foreground
                        opacity: 0.7
                        text: "Status"
                    }
                    Text {
                        color: (root.ethDevice && root.ethDevice.connected) ? Theme.selected : Theme.foreground
                        font.bold: true
                        text: {
                            if (!root.ethDevice)
                                return "Not available";
                            if (!root.ethDevice.hasLink)
                                return "Cable Disconnected";
                            return root.ethDevice.connected ? "Connected" : "Disconnected";
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    color: Theme.borderColor
                    height: 1
                    opacity: 0.5
                }
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        color: Theme.foreground
                        opacity: 0.7
                        text: "Interface"
                    }
                    Text {
                        color: Theme.foreground
                        font.bold: true
                        text: root.ethDevice ? root.ethDevice.name : "N/A"
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    color: Theme.borderColor
                    height: 1
                    opacity: 0.5
                }

                // MAC Address
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        color: Theme.foreground
                        opacity: 0.7
                        text: "MAC Address"
                    }
                    Text {
                        color: Theme.foreground
                        font.family: "monospace"
                        text: root.ethDevice ? root.ethDevice.address : "00:00:00:00:00:00"
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    color: Theme.borderColor
                    height: 1
                    opacity: 0.5
                    visible: root.ethDevice && root.ethDevice.hasLink
                }
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.ethDevice && root.ethDevice.hasLink

                    Text {
                        Layout.fillWidth: true
                        color: Theme.foreground
                        opacity: 0.7
                        text: "Connection Speed"
                    }
                    Text {
                        color: Theme.foreground
                        font.bold: true
                        text: (root.ethDevice && root.ethDevice.linkSpeed > 0) ? (root.ethDevice.linkSpeed + " Mbps") : "Unknown"
                    }
                }
            }
        }
        GlassCard {
            Layout.fillWidth: true
            implicitHeight: actionsLayout.implicitHeight + 30
            visible: root.ethDevice !== null

            ColumnLayout {
                id: actionsLayout

                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                // Autoconnect Toggle
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        color: Theme.foreground
                        font.bold: true
                        text: "Automatic Connect"
                    }

                    // Custom Switch
                    Rectangle {
                        border.color: Theme.borderColor
                        border.width: (root.ethDevice && root.ethDevice.autoconnect) ? 0 : 1
                        color: (root.ethDevice && root.ethDevice.autoconnect) ? Theme.selected : Theme.backgroundAlt
                        height: 24
                        radius: 12
                        width: 44

                        Rectangle {
                            color: Theme.foreground
                            height: 18
                            radius: 9
                            width: 18
                            x: (root.ethDevice && root.ethDevice.autoconnect) ? 23 : 3
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

                            onClicked: {
                                if (root.ethDevice) {
                                    root.ethDevice.autoconnect = !root.ethDevice.autoconnect;
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    color: root.ethDevice && root.ethDevice.connected ? Theme.color1 : Theme.selected
                    height: 40
                    radius: 8
                    visible: root.ethDevice && root.ethDevice.hasLink

                    Text {
                        anchors.centerIn: parent
                        color: Theme.background
                        font.bold: true
                        text: (root.ethDevice && root.ethDevice.connected) ? "Disconnect" : "Connect"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (!root.ethDevice)
                                return;

                            if (root.ethDevice.connected) {
                                NetworkService.ethernet.disconnect();
                            } else {
                                NetworkService.ethernet.connect();
                            }
                        }
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
    }
}
