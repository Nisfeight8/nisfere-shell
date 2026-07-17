import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Networking
import qs.core
import qs.services

Item {
    id: root

    implicitHeight: mainColumn.implicitHeight

    property string activeSsidPrompt: ""
    property var wifiDevice: NetworkService.wifi.device

    signal backRequested

    ColumnLayout {
        id: mainColumn
        width: parent.width
        spacing: 16

        // ── Header ───────────────────────────────────────────────
        PageHeader {
            Layout.fillWidth: true
            title: "Wi-Fi"
            onBackRequested: root.backRequested()

            ToggleSwitch {
                checked: NetworkService.wifiEnabled
                onToggled: NetworkService.wifi.toggle()
            }
        }

        // ── Network List (WiFi ON) ────────────────────────────────
        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(networksColumn.implicitHeight, 400)
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: NetworkService.wifiEnabled && root.wifiDevice !== null

            ColumnLayout {
                id: networksColumn
                width: scrollView.availableWidth
                spacing: 6

                SectionLabel {
                    Layout.bottomMargin: 6
                    title: "Available Networks"
                }

                Repeater {
                    model: root.wifiDevice ? root.wifiDevice.networks.values : null

                    delegate: GlassCard {
                        id: netCard
                        Layout.fillWidth: true

                        readonly property bool expanded: root.activeSsidPrompt === model.name
                        property string localError: ""
                        readonly property bool hasError: localError !== ""

                        implicitHeight: expanded ? (hasError ? 138 : 116) : 70
                        clip: true

                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }

                        Connections {
                            target: NetworkService.wifi
                            function onErrorOccurred(ssid, errorMessage) {
                                if (model.name === ssid) {
                                    netCard.localError = errorMessage;
                                    errorTimer.restart();
                                }
                            }
                        }

                        Timer {
                            id: errorTimer
                            interval: 10000
                            repeat: false
                            onTriggered: netCard.localError = ""
                        }

                        // ── Info row ────────────────────────────────
                        RowLayout {
                            id: infoRow
                            anchors {
                                top: parent.top
                                topMargin: 12
                                left: parent.left
                                leftMargin: 12
                                right: parent.right
                                rightMargin: 12
                            }
                            height: 46
                            spacing: 10

                            LucideIcon {
                                Layout.alignment: Qt.AlignVCenter
                                color: model.connected ? Theme.selected : Theme.foreground
                                size: 16
                                opacity: model.connected ? 1.0 : 0.75
                                icon: Icons.getWifiItemIcon(model.signalStrength)
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    color: Theme.foreground
                                    font.pixelSize: 13
                                    font.bold: model.connected
                                    text: model.name
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    color: model.connected ? Theme.selected : (netCard.hasError ? Theme.color1 : Theme.foreground)
                                    font.pixelSize: 11
                                    opacity: (model.connected || netCard.hasError) ? 1.0 : 0.5
                                    text: netCard.hasError ? "Connection Failed" : (model.connected ? "Connected" : "Saved")
                                    visible: model.connected || model.known || netCard.hasError
                                }
                            }

                            LucideIcon {
                                Layout.alignment: Qt.AlignVCenter
                                color: Theme.foreground
                                size: 14
                                opacity: 0.3
                                icon: "lock"
                                visible: model.security !== WifiSecurityType.Open && !model.connected && !model.known
                            }

                            // Per-network action button — custom multi-state
                            // logic (connected/expanded/hover intersect in
                            // ways that don't map cleanly onto IconButton's
                            // simpler idle/hover/active model), kept bespoke
                            // but using AnimColor for consistency.
                            Rectangle {
                                id: actionBtn
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                Layout.alignment: Qt.AlignVCenter
                                radius: Theme.radius
                                border.width: 1
                                border.color: Theme.borderColor
                                color: {
                                    if (!btnMouse.containsMouse)
                                        return (model.connected && !netCard.expanded) ? Theme.color1 : "transparent";
                                    return Theme.selected;
                                }
                                Behavior on color {
                                    AnimColor {
                                        type: Anim.FastEffects
                                    }
                                }

                                LucideIcon {
                                    anchors.centerIn: parent
                                    size: 16
                                    color: {
                                        if (btnMouse.containsMouse)
                                            return Theme.backgroundAlt;
                                        if (netCard.expanded || model.connected)
                                            return Theme.foreground;
                                        return Theme.selected;
                                    }
                                    icon: Icons.getWifiActionIcon(netCard.expanded, model.connected)
                                    Behavior on color {
                                        AnimColor {
                                            type: Anim.FastEffects
                                        }
                                    }
                                }

                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (netCard.expanded) {
                                            root.activeSsidPrompt = "";
                                            passwordInput.text = "";
                                            netCard.localError = "";
                                        } else if (model.connected) {
                                            NetworkService.wifi.disconnect();
                                        } else if (model.known || model.security === WifiSecurityType.Open) {
                                            NetworkService.wifi.connectTo(model.name);
                                        } else {
                                            root.activeSsidPrompt = model.name;
                                            Qt.callLater(() => passwordInput.forceActiveFocus());
                                        }
                                    }
                                }
                            }
                        }

                        // ── Password row ───────────────────────────
                        RowLayout {
                            id: passwordRow
                            anchors {
                                top: infoRow.bottom
                                topMargin: 8
                                left: parent.left
                                leftMargin: 12
                                right: parent.right
                                rightMargin: 12
                            }
                            height: 38
                            spacing: 8
                            opacity: netCard.expanded ? 1.0 : 0.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 160
                                }
                            }

                            TextField {
                                id: passwordInput
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                implicitHeight: 34
                                color: Theme.foreground
                                echoMode: TextInput.Password
                                placeholderText: "Password…"
                                placeholderTextColor: netCard.hasError ? Qt.alpha(Theme.color1, 0.6) : Theme.borderColor
                                font.pixelSize: 13
                                leftPadding: 10
                                rightPadding: 10

                                background: Rectangle {
                                    border.color: netCard.hasError ? Theme.color1 : Theme.borderColor
                                    border.width: Theme.widgetBorderWidth
                                    color: Theme.backgroundAlt
                                    radius: Theme.radius
                                    Behavior on border.color {
                                        AnimColor {
                                            type: Anim.FastEffects
                                        }
                                    }
                                }

                                Keys.onReturnPressed: {
                                    netCard.localError = "";
                                    NetworkService.wifi.connectTo(model.name, text);
                                }
                            }

                            // Confirm button — fits IconButton cleanly:
                            // constant selected bg, lightens on hover.
                            IconButton {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                icon: "check"
                                size: 34
                                iconSize: 16
                                normalColor: Theme.selected
                                hoverColor: Qt.lighter(Theme.selected, 1.15)
                                hoverSolid: true
                                fixedIconColor: Theme.background
                                dimWhenIdle: false
                                onTapped: {
                                    netCard.localError = "";
                                    NetworkService.wifi.connectTo(model.name, passwordInput.text);
                                }
                            }
                        }

                        // ── Error text ──────────────────────────────
                        Text {
                            anchors {
                                top: passwordRow.bottom
                                topMargin: 4
                                left: parent.left
                                leftMargin: 16
                                right: parent.right
                                rightMargin: 12
                            }
                            text: netCard.localError
                            color: Theme.color1
                            font.pixelSize: 11
                            opacity: netCard.hasError ? 1.0 : 0.0
                            visible: opacity > 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── WiFi Off State ─────────────────────────────────────────
        DisabledStateCard {
            Layout.fillWidth: true
            implicitHeight: 150
            visible: !NetworkService.wifiEnabled
            icon: "wifi-off"
            message: "Wi-Fi is turned off"
        }
    }
}
