import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.core
import qs.services
import Quickshell.Networking

Item {
    id: root
    anchors.fill: parent

    property string activeSsidPrompt: ""
    property var wifiDevice: NetworkService.wifi.device

    signal backRequested

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        // ── HEADER ───────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: backMouse.containsMouse ? Theme.backgroundAlt : "transparent"
                border.color: Theme.borderColor
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰁍"
                    color: Theme.foreground
                    font.pixelSize: 16
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
                width: 44
                height: 24
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

        // ── NETWORK LIST ─────────────────────────────────────────────────────
        ScrollView {
            id: scrollView
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            visible: NetworkService.wifiEnabled && root.wifiDevice !== null

            ColumnLayout {
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

                        // State properties
                        readonly property bool expanded: root.activeSsidPrompt === model.name
                        property string localError: "" // Κρατάει το μήνυμα λάθους για αυτό το δίκτυο
                        readonly property bool hasError: localError !== ""

                        // Collapsed: 70
                        // Expanded (Normal): 116
                        // Expanded (Με Error): 138 (προσθέτουμε χώρο για το text)
                        implicitHeight: expanded ? (hasError ? 138 : 116) : 70
                        clip: true

                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }

                        // Ακούμε το signal από το Service
                        Connections {
                            target: NetworkService.wifi

                            function onErrorOccurred(ssid, errorMessage) {
                                // Ελέγχουμε αν το λάθος αφορά αυτό ακριβώς το δίκτυο
                                if (model.name === ssid) {
                                    netCard.localError = errorMessage;
                                    errorTimer.restart();
                                }
                            }
                        }

                        // Timer για να καθαρίζει το μήνυμα λάθους μετά από 3 δευτερόλεπτα
                        Timer {
                            id: errorTimer
                            interval: 10000
                            repeat: false
                            onTriggered: {
                                netCard.localError = "";
                            }
                        }

                        // ── Network info row ─────────────────────────────
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

                            // Signal strength icon
                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                color: model.connected ? Theme.selected : Theme.foreground
                                font.pixelSize: 16
                                opacity: model.connected ? 1.0 : 0.75
                                text: {
                                    const s = model.signalStrength;
                                    if (s > 0.8)
                                        return "󰤨";
                                    if (s > 0.6)
                                        return "󰤥";
                                    if (s > 0.4)
                                        return "󰤢";
                                    if (s > 0.2)
                                        return "󰤟";
                                    return "󰤯";
                                }
                            }

                            // Network name + status
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

                            // Lock icon
                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                color: Theme.foreground
                                font.pixelSize: 11
                                opacity: 0.3
                                text: "󰌾"
                                visible: model.security !== WifiSecurityType.Open && !model.connected && !model.known
                            }

                            // Action button
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                width: 30
                                height: 30
                                radius: Theme.radius

                                color: {
                                    if (!btnMouse.containsMouse) {
                                        return (model.connected && !netCard.expanded) ? Theme.color1 : "transparent";
                                    }
                                    return Theme.selected;
                                }

                                border.width: 1
                                border.color: Theme.borderColor

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    font.pixelSize: 13
                                    color: {
                                        if (btnMouse.containsMouse) {
                                            return Theme.backgroundAlt;
                                        } else {
                                            if (netCard.expanded || model.connected)
                                                return Theme.foreground;
                                            return Theme.selected;
                                        }
                                    }
                                    text: (netCard.expanded || model.connected) ? "󰅖" : "󰄬"
                                }

                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (netCard.expanded) {
                                            // Cancel password entry
                                            root.activeSsidPrompt = "";
                                            passwordInput.text = "";
                                            netCard.localError = ""; // Clear error on cancel
                                        } else if (model.connected) {
                                            NetworkService.wifi.disconnect();
                                        } else if (model.known || model.security === WifiSecurityType.Open) {
                                            NetworkService.wifi.connectTo(model.name);
                                        } else {
                                            root.activeSsidPrompt = model.name;
                                            Qt.callLater(function () {
                                                passwordInput.forceActiveFocus();
                                            });
                                        }
                                    }
                                }
                            }
                        }

                        // ── Password row (slides in from below via clip) ──
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
                                    // ΕΔΩ: Κοκκινίζει το border αν υπάρχει λάθος
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
                                    netCard.localError = ""; // Καθαρίζουμε το UI για νέα προσπάθεια
                                    NetworkService.wifi.connectTo(model.name, text);
                                    // Αφαιρέθηκε το root.activeSsidPrompt = "" για να μείνει ανοιχτό και να δούμε αν θα πετύχει/αποτύχει
                                }
                            }

                            // Confirm / connect button
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                width: 34
                                height: 34
                                radius: Theme.radius
                                color: confirmMouse.containsMouse ? Qt.lighter(Theme.selected, 1.15) : Theme.selected
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄬"
                                    color: Theme.background
                                    font.pixelSize: 14
                                    font.bold: true
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

                        // ── Error Message Text ──
                        Text {
                            anchors {
                                top: passwordRow.bottom
                                topMargin: 4
                                left: parent.left
                                leftMargin: 16 // Λίγο πιο μέσα για ευθυγράμμιση με το text field
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

        // ── WI-FI OFF STATE ──────────────────────────────────────────────────
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            visible: !NetworkService.wifiEnabled

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.foreground
                    font.pixelSize: 52
                    opacity: 0.2
                    text: "󰖪"
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
