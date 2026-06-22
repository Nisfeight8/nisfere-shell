import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.core
import qs.services
import Quickshell.Networking

Item {
    id: root

    property string activeSsidPrompt: ""
    property var wifiDevice: NetworkService.wifi.device

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
                text: "Wi-Fi Settings"
            }
            Rectangle {
                border.color: Theme.borderColor
                border.width: NetworkService.wifiEnabled ? 0 : 1
                color: NetworkService.wifiEnabled ? Theme.selected : Theme.backgroundAlt
                height: 24
                radius: 12
                width: 44

                Rectangle {
                    color: Theme.foreground
                    height: 18
                    radius: 9
                    width: 18
                    x: NetworkService.wifiEnabled ? 23 : 3
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

                    onClicked: NetworkService.wifi.toggle()
                }
            }
        }
        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            clip: true
            visible: NetworkService.wifiEnabled && root.wifiDevice !== null

            ColumnLayout {
                spacing: 10
                width: parent.width

                Text {
                    Layout.bottomMargin: 5
                    color: Theme.foreground
                    font.bold: true
                    opacity: 0.7
                    text: "Available Networks"
                }
                Repeater {
                    model: root.wifiDevice ? root.wifiDevice.networks : null

                    delegate: GlassCard {
                        Layout.fillWidth: true
                        implicitHeight: (root.activeSsidPrompt === model.name) ? 120 : 60

                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.margins: 15
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 60
                            spacing: 15

                            Text {
                                color: model.connected ? Theme.selected : Theme.foreground
                                font.pixelSize: 20
                                text: {
                                    let s = model.signalStrength;
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
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    color: Theme.foreground
                                    elide: Text.ElideRight
                                    font.bold: true
                                    text: model.name
                                }
                                Text {
                                    color: model.connected ? Theme.selected : Theme.foreground
                                    font.pixelSize: 11
                                    opacity: model.connected ? 1.0 : 0.6
                                    text: model.connected ? "Connected" : "Saved"
                                    visible: model.connected || model.known
                                }
                            }
                            Text {
                                color: Theme.foreground
                                font.pixelSize: 16
                                opacity: 0.5
                                text: "󰌾"
                                visible: model.security !== WifiSecurityType.Open && !model.connected && !model.known
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: root.activeSsidPrompt !== model.name

                            onClicked: {
                                if (model.connected) {
                                    NetworkService.wifi.disconnect();
                                } else if (model.known || model.security === WifiSecurityType.Open) {
                                    NetworkService.wifi.connectTo(model.name);
                                } else {
                                    root.activeSsidPrompt = model.name;
                                    passwordInput.forceActiveFocus();
                                }
                            }
                        }
                        RowLayout {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.margins: 15
                            anchors.right: parent.right
                            height: 60
                            opacity: visible ? 1 : 0
                            visible: root.activeSsidPrompt === model.name

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }
                            }

                            TextField {
                                id: passwordInput

                                Layout.fillWidth: true
                                color: Theme.foreground
                                echoMode: TextInput.Password
                                placeholderText: "Enter a password..."
                                placeholderTextColor: Theme.borderColor

                                background: Rectangle {
                                    border.color: Theme.borderColor
                                    border.width: 1
                                    color: Theme.backgroundAlt
                                    radius: 6
                                }

                                Keys.onReturnPressed: connectBtn.clicked()
                            }
                            Rectangle {
                                color: Theme.backgroundAlt
                                height: 36
                                radius: 18
                                width: 36

                                Text {
                                    anchors.centerIn: parent
                                    color: Theme.foreground
                                    font.pixelSize: 16
                                    text: "󰅖"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        root.activeSsidPrompt = "";
                                        passwordInput.text = "";
                                    }
                                }
                            }
                            Rectangle {
                                color: Theme.selected
                                height: 36
                                radius: 18
                                width: 36

                                Text {
                                    anchors.centerIn: parent
                                    color: Theme.background
                                    font.bold: true
                                    font.pixelSize: 16
                                    text: "󰄬"
                                }
                                MouseArea {
                                    id: connectBtn

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        NetworkService.wifi.connectTo(model.name, passwordInput.text);
                                        root.activeSsidPrompt = "";
                                        passwordInput.text = "";
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
            visible: !NetworkService.wifiEnabled

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 15

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.foreground
                    font.pixelSize: 64
                    opacity: 0.3
                    text: "󰖪"
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.foreground
                    font.pixelSize: 16
                    opacity: 0.6
                    text: "Wi-Fi is turned off"
                }
            }
        }
    }
}
