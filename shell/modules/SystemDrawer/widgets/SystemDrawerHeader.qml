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
                    // visible: !avatar.visible
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

                    Rectangle {
                        id: btn
                        width: 32
                        height: 32
                        radius: 8
                        // ↓ Use explicit property — avoids forward-reference
                        //   issue with HoverHandler id inside Repeater delegates
                        property bool isHovered: false
                        color: isHovered ? Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.18) : "transparent"
                        border.width: isHovered ? 1 : 0
                        border.color: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.35)
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on border.width {
                            NumberAnimation {
                                duration: 150
                            }
                        }

                        LucideIcon {
                            anchors.centerIn: parent
                            icon: modelData.icon
                            size: 16
                            color: btn.isHovered ? Theme.color1 : Theme.foreground
                            opacity: btn.isHovered ? 1.0 : 0.4
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                            // Set property imperatively — no forward reference
                            onHoveredChanged: btn.isHovered = hovered
                        }
                        TapHandler {
                            onTapped: root._run(modelData.cmd)
                        }
                    }
                }
            }
        }

        // ── OS info strip ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: 8
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
