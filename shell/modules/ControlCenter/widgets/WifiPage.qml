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
        width: parent.width   // top-down, ΟΧΙ anchors.fill!
        spacing: 16

        // ── Header ───────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 32   // ✓
                Layout.preferredHeight: 32  // ✓
                Layout.alignment: Qt.AlignVCenter
                radius: 16
                color: backMouse.containsMouse ? Theme.backgroundAlt : "transparent"
                border.color: Theme.borderColor
                border.width: 1

                LucideIcon {
                    anchors.centerIn: parent
                    icon: "arrow-left"
                    size: 16
                    color: Theme.foreground
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Wi-Fi"
                color: Theme.foreground
                font.bold: true
                font.pixelSize: 18
                verticalAlignment: Text.AlignVCenter
            }

            // Toggle switch
            Rectangle {
                Layout.preferredWidth: 44   // ✓
                Layout.preferredHeight: 24  // ✓
                Layout.alignment: Qt.AlignVCenter
                radius: 12
                color: NetworkService.wifiEnabled ? Theme.selected : Theme.backgroundAlt
                border.color: Theme.borderColor
                border.width: NetworkService.wifiEnabled ? 0 : 1

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: Theme.foreground
                    y: 3
                    x: NetworkService.wifiEnabled ? 23 : 3

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
                    onClicked: NetworkService.wifi.toggle()
                }
            }
        }

        // ── Network List (WiFi ON) ────────────────────────────────────────
        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            // Cap: content ύψος ή 400px max — ΟΧΙ fillHeight ✓
            Layout.preferredHeight: Math.min(networksColumn.implicitHeight, 400)
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: NetworkService.wifiEnabled && root.wifiDevice !== null

            ColumnLayout {
                id: networksColumn   // ← id για το implicitHeight
                width: scrollView.availableWidth
                spacing: 6

                Text {
                    Layout.bottomMargin: 6
                    text: "AVAILABLE NETWORKS"
                    color: Theme.foreground
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.0
                    opacity: 0.45
                }

                Repeater {
                    model: root.wifiDevice ? root.wifiDevice.networks.values : null

                    delegate: GlassCard {
                        id: netCard
                        Layout.fillWidth: true

                        readonly property bool expanded: root.activeSsidPrompt === model.name
                        property string localError: ""
                        readonly property bool hasError: localError !== ""

                        // implicitHeight: per card — σωστό ✓
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

                        // ── Info row — anchors OK γιατί GlassCard έχει explicit implicitHeight
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

                            // Action button — μέσα σε RowLayout → Layout.preferred ✓
                            Rectangle {
                                Layout.preferredWidth: 30   // ✓
                                Layout.preferredHeight: 30  // ✓
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
                                    ColorAnimation {
                                        duration: 100
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

                        // ── Password row
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
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }

                                Keys.onReturnPressed: {
                                    netCard.localError = "";
                                    NetworkService.wifi.connectTo(model.name, text);
                                }
                            }

                            // Confirm button — μέσα σε RowLayout → Layout.preferred ✓
                            Rectangle {
                                Layout.preferredWidth: 34   // ✓
                                Layout.preferredHeight: 34  // ✓
                                Layout.alignment: Qt.AlignVCenter
                                radius: Theme.radius
                                color: confirmMouse.containsMouse ? Qt.lighter(Theme.selected, 1.15) : Theme.selected

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }

                                LucideIcon {
                                    anchors.centerIn: parent
                                    size: 16
                                    color: Theme.background
                                    icon: "check"
                                }

                                MouseArea {
                                    id: confirmMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        netCard.localError = "";
                                        NetworkService.wifi.connectTo(model.name, passwordInput.text);
                                    }
                                }
                            }
                        }

                        // ── Error text
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

        // ── WiFi Off State ────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            implicitHeight: 150   // ✓ fixed
            visible: !NetworkService.wifiEnabled

            ColumnLayout {
                anchors.centerIn: parent   // actual positioning ✓
                spacing: 10

                LucideIcon {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.foreground
                    size: 52
                    opacity: 0.2
                    icon: "wifi-off"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.foreground
                    font.pixelSize: 13
                    opacity: 0.45
                    text: "Wi-Fi is turned off"
                }
            }
        }
    }
}
