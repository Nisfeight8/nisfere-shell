import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services

BaseDrawer {
    id: powerMenu

    edge: Qt.RightEdge
    opened: ShellState.powerMenuOpened
    panelHeight: 450
    panelWidth: 110

    onCloseRequest: ShellState.powerMenuOpened = false
    onOpenRequest: ShellState.powerMenuOpened = true
    onToggleRequest: ShellState.powerMenuOpened = !ShellState.powerMenuOpened

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Repeater {
            model: [
                {
                    icon: "",
                    cmd: ["systemctl", "poweroff"],
                    color: "#f38ba8"
                },
                {
                    icon: "",
                    cmd: ["systemctl", "reboot"],
                    color: "#fab387"
                },
                {
                    icon: "",
                    cmd: ["systemctl", "suspend"],
                    color: "#89b4fa"
                },
                {
                    icon: "",
                    cmd: ["hyprctl", "dispatch", "exit"],
                    color: "#a6e3a1"
                }
            ]

            delegate: Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 64
                Layout.preferredWidth: 64
                border.color: powerMouse.containsMouse ? modelData.color : "transparent"
                border.width: 2
                color: Theme.backgroundAlt
                radius: 32

                Rectangle {
                    anchors.fill: parent
                    color: modelData.color
                    opacity: powerMouse.containsMouse ? 0.2 : 0
                    radius: 32

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    color: powerMouse.containsMouse ? modelData.color : Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 28
                    text: modelData.icon

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
                MouseArea {
                    id: powerMouse

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        ShellState.powerMenuOpened = false;
                        Quickshell.execDetached({
                            command: modelData.cmd
                        });
                    }
                }
            }
        }
    }
}
