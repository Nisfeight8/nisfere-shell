import QtQuick
import QtQuick.Layouts
import qs.core

// Icon+label navigation tile — for grids/rows of "go somewhere" or
// "select this" actions (IconButton is the icon-only equivalent).
//
// Consistent state pattern used across the shell from here on:
//   idle    → backgroundAlt bg, foreground text/icon
//   hover   → tinted hoverColor bg (15%), hoverColor text/icon, hoverColor border
//   active  → SOLID activeColor bg, backgroundAlt text/icon (contrast)
//
// Usage:
//   NavTile {
//       Layout.fillWidth: true
//       icon: "image"; label: "Wallpapers"
//       onTapped: ShellState.quickAction = "wallpaper"
//   }
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool ready: true   // false = "coming soon" / disabled state
    property string subLabel: ""   // shown instead of nothing when !ready

    property color hoverColor: Theme.selected
    property color activeColor: Theme.selected
    property bool isActive: false

    readonly property bool isHovered: hover.hovered

    signal tapped

    // implicitHeight (not height!) — lets a consumer override via
    // Layout.preferredHeight (e.g. a more compact scan-button instance)
    // while still defaulting to 36 everywhere else.
    implicitHeight: 36
    radius: Theme.radius

    color: !ready ? Theme.backgroundAlt : isActive ? activeColor : isHovered ? Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0.15) : Theme.backgroundAlt
    border.width: 1
    border.color: !ready ? Theme.borderColor : isActive ? activeColor : isHovered ? hoverColor : Theme.borderColor
    opacity: ready ? 1.0 : 0.55

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

    RowLayout {
        anchors.centerIn: parent
        // Was anchors.centerIn: parent with no width limit at all —
        // fine while the tile is wide, but nothing stopped a long
        // label from pushing this RowLayout (and the Text inside it)
        // wider than the tile itself. Clamping to the tile's own
        // width (minus a little breathing room) is what makes the
        // elide below actually able to kick in.
        width: Math.max(0, Math.min(implicitWidth, root.width - 16))
        spacing: 7

        LucideIcon {
            icon: root.icon
            size: 15
            visible: root.icon !== ""
            color: root.isActive ? Theme.backgroundAlt : root.isHovered && root.ready ? root.hoverColor : Theme.foreground
            Behavior on color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: root.label
                color: root.isActive ? Theme.backgroundAlt : root.isHovered && root.ready ? root.hoverColor : Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13
                font.bold: root.isActive
                elide: Text.ElideRight
                Behavior on color {
                    AnimColor {
                        type: Anim.FastEffects
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                visible: !root.ready && root.subLabel !== ""
                text: root.subLabel
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 9
                opacity: 0.5
                elide: Text.ElideRight
            }
        }
    }

    HoverHandler {
        id: hover
        enabled: root.ready
        cursorShape: root.ready ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    TapHandler {
        enabled: root.ready
        onTapped: root.tapped()
    }
}
