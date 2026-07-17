import QtQuick
import QtQuick.Layouts
import qs.core

// Generic circular icon button with label underneath, hover/active states,
// tooltip, and an optional pulsing ring (e.g. for "recording" indicators).
// Knows nothing about what it triggers — purely presentational.
//
// Consistent state pattern used across the shell:
//   idle    → background bg, foreground text/icon
//   hover   → tinted hoverColor bg (15%), hoverColor text/icon
//   active  → SOLID activeColor bg, backgroundAlt text/icon (contrast)
ColumnLayout {
    id: root

    property string icon: ""
    property string label: ""
    property bool showLabel: true    // set false for icon-only buttons (tooltip still works)
    property bool isActive: false
    property bool showPulse: false   // e.g. recording indicator ring
    property color pulseColor: Theme.color1
    property color activeColor: Theme.color1    // color when isActive is true
    property color hoverColor: Theme.selected  // color on hover (not active)
    property string tooltipText: label
    property int diameter: 52
    property int iconSize: 20

    readonly property bool isHovered: hover.hovered
    readonly property color _stateColor: root.isActive ? Theme.backgroundAlt : root.isHovered ? root.hoverColor : Theme.foreground

    signal tapped

    spacing: 6

    Rectangle {
        id: circle
        Layout.alignment: Qt.AlignHCenter
        width: root.diameter
        height: root.diameter
        radius: width / 2

        color: root.isActive ? root.activeColor : root.isHovered ? Qt.rgba(root.hoverColor.r, root.hoverColor.g, root.hoverColor.b, 0.25) : Theme.background
        border.width: Theme.widgetBorderWidth
        border.color: root.isActive ? root.activeColor : root.isHovered ? root.hoverColor : Theme.borderColor

        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
        Behavior on border.color {
            AnimColor {
                type: Anim.FastEffects
            }
        }

        LucideIcon {
            anchors.centerIn: parent
            icon: root.icon
            size: root.iconSize
            color: root._stateColor
            opacity: root.isActive ? 1.0 : root.isHovered ? 0.95 : 0.65
            Behavior on color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        // Optional pulsing ring — parent decides when to show it
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 2
            border.color: root.pulseColor
            visible: root.showPulse
            opacity: 0.7

            SequentialAnimation on opacity {
                running: root.showPulse
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0.15
                    duration: 700
                }
                NumberAnimation {
                    to: 0.7
                    duration: 700
                }
            }
        }

        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: root.tapped()
        }
        StyledToolTip {
            visible: root.isHovered && root.tooltipText !== ""
            text: root.tooltipText
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: root.showLabel
        text: root.label
        color: root.isActive ? root.activeColor : root.isHovered ? root.hoverColor : Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 10
        opacity: root.isActive ? 1.0 : root.isHovered ? 0.9 : 0.6
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
    }
}
