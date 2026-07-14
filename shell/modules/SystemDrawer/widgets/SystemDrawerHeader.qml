import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.core
import qs.services

Item {
    id: root
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    property Process _proc: Process {
        running: false
    }
    function _run(cmd) {
        _proc.command = cmd;
        _proc.running = true;
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 10

        // ── User row ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            // Avatar
            Rectangle {
                width: 56
                height: 56
                radius: 28
                color: Theme.backgroundAlt
                clip: true
                Image {
                    id: avatar
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: ""
                    visible: source !== ""
                }
                LucideIcon {
                    anchors.centerIn: parent
                    icon: "user"
                    size: 26
                    color: Theme.selected
                }
            }

            // Username + uptime
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    text: SystemInfo.username
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 20
                    font.bold: true
                }
                RowLayout {
                    spacing: 5
                    LucideIcon {
                        icon: "clock-3"
                        size: 12
                        color: Theme.selected
                    }
                    Text {
                        text: SystemInfo.uptime
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 12
                        opacity: 0.6
                    }
                }
            }

            // ← spacer pushes buttons to far right
            Item {
                Layout.fillWidth: true
            }

            // Power buttons — far right
            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                Repeater {
                    model: [
                        {
                            icon: "lock",
                            cmd: ["loginctl", "lock-session"]
                        },
                        {
                            icon: "rotate-ccw",
                            cmd: ["systemctl", "reboot"]
                        },
                        {
                            icon: "power",
                            cmd: ["systemctl", "poweroff"]
                        },
                    ]

                    IconButton {
                        icon: modelData.icon
                        size: 32
                        iconSize: 16
                        radius: Theme.radius
                        hoverColor: Theme.color1
                        activeColor: Theme.color1
                        idleOpacity: 0.4
                        onTapped: root._run(modelData.cmd)
                    }
                }
            }
        }

        // ── OS info strip ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: Theme.radius
            color: Theme.backgroundAlt

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }
                spacing: 8
                LucideIcon {
                    icon: "box"
                    size: 18
                    color: Theme.selected
                }
                Text {
                    text: SystemInfo.osName
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    opacity: 0.85
                }
                Rectangle {
                    width: 1
                    height: 10
                    color: Theme.borderColor
                    opacity: 0.5
                }
                LucideIcon {
                    icon: "layout-dashboard"
                    size: 18
                    color: Theme.selected
                }
                Text {
                    text: SystemInfo.windowManager
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    opacity: 0.85
                }
            }
        }
    }
}
