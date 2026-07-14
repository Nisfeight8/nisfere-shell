import QtQuick
import QtQuick.Layouts
import qs.core

// Icon+label navigation tile — for grids of "go somewhere" actions
// (as opposed to IconButton, which is icon-only for compact toolbars).
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

    height: 36
    radius: Theme.radius

    color: !ready ? Theme.backgroundAlt : isActive ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.15) : isHovered ? Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0.15) : Theme.backgroundAlt
    border.width: 1
    border.color: !ready ? Theme.borderColor : isActive ? activeColor : isHovered ? hoverColor : Theme.borderColor
    opacity: ready ? 1.0 : 0.55


    RowLayout {
        anchors.centerIn: parent
        spacing: 7

        LucideIcon {
            icon: root.icon
            size: 15
            color: root.isActive ? root.activeColor : root.isHovered && root.ready ? root.hoverColor : Theme.foreground
            Behavior on color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }
        }

        ColumnLayout {
            spacing: 0
            Text {
                text: root.label
                color: root.isActive ? root.activeColor : root.isHovered && root.ready ? root.hoverColor : Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12
                Behavior on color {
                    AnimColor {
                        type: Anim.FastEffects
                    }
                }
            }
            Text {
                visible: !root.ready && root.subLabel !== ""
                text: root.subLabel
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 9
                opacity: 0.5
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
