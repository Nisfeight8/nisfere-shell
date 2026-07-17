import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    property var ethDevice: NetworkService.ethernet.device

    signal backRequested

    implicitHeight: mainColumn.implicitHeight

    ColumnLayout {
        id: mainColumn
        width: parent.width
        spacing: 20

        // ── Header ───────────────────────────────────────────────
        PageHeader {
            Layout.fillWidth: true
            title: "Ethernet Settings"
            onBackRequested: root.backRequested()
        }

        // ── Info Card ──────────────────────────────────────────────
        GlassCard {
            Layout.fillWidth: true
            implicitHeight: infoLayout.implicitHeight + 30

            ColumnLayout {
                id: infoLayout
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                InfoRow {
                    label: "Status"
                    valueColor: (root.ethDevice && root.ethDevice.connected) ? Theme.selected : Theme.foreground
                    value: {
                        if (!root.ethDevice)
                            return "Not available";
                        if (!root.ethDevice.hasLink)
                            return "Cable Disconnected";
                        return root.ethDevice.connected ? "Connected" : "Disconnected";
                    }
                }

                InfoDivider {}

                InfoRow {
                    label: "Interface"
                    value: root.ethDevice ? root.ethDevice.name : "N/A"
                }

                InfoDivider {}

                InfoRow {
                    label: "MAC Address"
                    valueBold: false
                    value: root.ethDevice ? root.ethDevice.address : "00:00:00:00:00:00"
                }

                InfoDivider {
                    visible: root.ethDevice && root.ethDevice.hasLink
                }

                InfoRow {
                    visible: root.ethDevice && root.ethDevice.hasLink
                    label: "Connection Speed"
                    value: (root.ethDevice && root.ethDevice.linkSpeed > 0) ? (root.ethDevice.linkSpeed + " Mbps") : "Unknown"
                }
            }
        }

        // ── Actions Card ───────────────────────────────────────────
        GlassCard {
            Layout.fillWidth: true
            implicitHeight: actionsLayout.implicitHeight + 30
            visible: root.ethDevice !== null

            ColumnLayout {
                id: actionsLayout
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: "Automatic Connect"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 16
                        font.bold: true
                    }

                    ToggleSwitch {
                        Layout.alignment: Qt.AlignVCenter
                        checked: root.ethDevice ? root.ethDevice.autoconnect : false
                        onToggled: {
                            if (root.ethDevice)
                                root.ethDevice.autoconnect = !root.ethDevice.autoconnect;
                        }
                    }
                }

                ActionButton {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    visible: root.ethDevice && root.ethDevice.hasLink
                    label: (root.ethDevice && root.ethDevice.connected) ? "Disconnect" : "Connect"
                    baseColor: (root.ethDevice && root.ethDevice.connected) ? Theme.color1 : Theme.selected
                    onTapped: {
                        if (!root.ethDevice)
                            return;
                        if (root.ethDevice.connected)
                            NetworkService.ethernet.disconnect();
                        else
                            NetworkService.ethernet.connect();
                    }
                }
            }
        }
    }
}
