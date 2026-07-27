import QtQuick
import qs.core

// Standard pill toggle switch. Parent controls the actual state change
// (onToggled just signals intent) — matches the pattern of flipping an
// external property like `device.autoconnect`.
// Usage:
//   ToggleSwitch {
//       checked: device.autoconnect
//       onToggled: device.autoconnect = !device.autoconnect
//   }
Rectangle {
    id: root

    property bool checked: false
    signal toggled

    readonly property bool isHovered: hover.hovered

    width: 44
    height: 24
    radius: 12
    color: checked ? Theme.selected : Theme.backgroundAlt
    border.width: checked ? 0 : 1
    border.color: isHovered ? Theme.selected : Theme.borderColor

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

    Rectangle {
        width: 18
        height: 18
        radius: 9
        y: (parent.height - height) / 2
        x: root.checked ? parent.width - width - 3 : 3
        color: root.checked ? Theme.background : Theme.foreground

        Behavior on x {
            Anim {
                type: Anim.FastToggle
            }
        }
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        onTapped: root.toggled()
    }
}
