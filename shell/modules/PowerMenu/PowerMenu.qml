import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

PanelWindow {
    id: powerMenu

    visible: ShellState.powerMenuOpened
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Shortcut {
        sequence: "Escape"
        onActivated: ShellState.powerMenuOpened = false
    }

    GlassBackground {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.4
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.powerMenuOpened = false
    }

    Item {
        id: menuContainer
        anchors.fill: parent

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 60

            // --- HEADER ---
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Text {
                    text: "Goodbye, " + SystemInfo.username
                    font.family: Theme.fontName
                    font.pixelSize: 32
                    font.bold: true
                    color: Theme.selected
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: SystemInfo.osName + " • " + SystemInfo.uptime
                    font.family: Theme.fontName
                    font.pixelSize: 16
                    color: Theme.selected
                    opacity: 0.7
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // --- BUTTONS ---
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 40

                Repeater {
                    model: [
                        {
                            icon: "power",
                            label: "Shutdown",
                            cmd: ["systemctl", "poweroff"],
                            color: Theme.color1
                        },
                        {
                            icon: "refresh-cw",
                            label: "Reboot",
                            cmd: ["systemctl", "reboot"],
                            color: Theme.color3
                        },
                        {
                            icon: "moon",
                            label: "Suspend",
                            cmd: ["systemctl", "suspend"],
                            color: Theme.color4
                        },
                        {
                            icon: "log-out",
                            label: "Logout",
                            cmd: ["hyprctl", "dispatch", "exit"],
                            color: Theme.color2
                        }
                    ]

                    delegate: Rectangle {
                        width: 140
                        height: 140
                        color: Theme.backgroundAlt
                        radius: 70
                        border.color: btnMouse.containsMouse ? modelData.color : "transparent"
                        border.width: 3

                        Rectangle {
                            anchors.fill: parent
                            color: modelData.color
                            opacity: btnMouse.containsMouse ? 0.2 : 0
                            radius: parent.radius
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        LucideIcon {
                            anchors.centerIn: parent
                            icon: modelData.icon
                            size: 48
                            color: btnMouse.containsMouse ? modelData.color : Theme.foreground
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }

                        ToolTip {
                            visible: btnMouse.containsMouse
                            text: modelData.label
                            delay: 200
                            y: parent.height + 15
                            x: (parent.width - width) / 2

                            padding: 6
                            leftPadding: 12
                            rightPadding: 12

                            contentItem: Text {
                                text: modelData.label
                                color: Theme.selected
                                font.family: Theme.fontName
                                font.pixelSize: 14
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: Theme.backgroundAlt
                                border.color: Theme.borderColor
                                border.width: 1
                                radius: 8
                            }
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true

                            onClicked: {
                                ShellState.powerMenuOpened = false;
                                Quickshell.execDetached(modelData.cmd);
                            }
                        }
                    }
                }
            }
        }
    }
}
