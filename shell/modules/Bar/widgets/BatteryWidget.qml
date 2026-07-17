import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

BarWidget {
    id: root

    visible: BatteryService.hasBattery
    bgColor: "transparent"
    spacing: 6

    readonly property bool isCritical: !BatteryService.isCharging && BatteryService.percentage <= 15
    readonly property color statusColor: BatteryService.isCharging ? Theme.selected : (isCritical ? Theme.color1 : Theme.foreground)

    // ── Compact bar display — icon + percentage ────────────────────
    LucideIcon {
        id: battIcon
        anchors.verticalCenter: parent.verticalCenter
        icon: Icons.getBatteryIcon(BatteryService.percentage, BatteryService.isCharging)
        size: 16
        color: root.statusColor
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }

        // Gentle pulse when critically low and not charging — same
        // "needs attention" visual language as the recording indicator.
        SequentialAnimation on opacity {
            running: root.isCritical
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.4
                duration: 700
            }
            NumberAnimation {
                to: 1.0
                duration: 700
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: BatteryService.percentage + "%"
        color: root.statusColor
        font.family: Theme.fontName
        font.pixelSize: 13
        font.bold: BatteryService.isCharging || root.isCritical
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }

    HoverHandler {
        id: hover
    }

    // ── Rich detail popup — icon badge, %, status, progress, time ──
    BarPopup {
        showPopup: hover.hovered
        targetItem: root

        contentComponent: Component {
            ColumnLayout {
                spacing: 12

                RowLayout {
                    spacing: 12

                    Rectangle {
                        width: 48
                        height: 48
                        radius: 24
                        color: Theme.backgroundAlt
                        border.width: 1
                        border.color: Theme.borderColor

                        LucideIcon {
                            anchors.centerIn: parent
                            icon: Icons.getBatteryIcon(BatteryService.percentage, BatteryService.isCharging)
                            size: 24
                            color: root.statusColor
                        }
                    }

                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: BatteryService.percentage + "%"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 22
                            font.bold: true
                        }
                        Text {
                            text: BatteryService.stateName
                            color: root.statusColor
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }

                // Progress bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Theme.backgroundAlt

                    Rectangle {
                        height: parent.height
                        radius: 3
                        color: root.statusColor
                        width: parent.width * (BatteryService.percentage / 100)
                        Behavior on width {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                        Behavior on color {
                            AnimColor {
                                type: Anim.FastEffects
                            }
                        }
                    }
                }

                // Time remaining / until full
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    LucideIcon {
                        icon: "clock-3"
                        size: 13
                        color: Theme.foreground
                        opacity: 0.6
                    }
                    Text {
                        Layout.fillWidth: true
                        text: BatteryService.timeText
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 12
                        opacity: 0.75
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
