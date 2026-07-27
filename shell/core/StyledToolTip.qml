import QtQuick
import QtQuick.Controls
import qs.core

// Themed tooltip — positioned centered below its parent by default.
// NOTE: only works reliably in drawers/panels — do NOT use inside the
// Bar (its Popup/Overlay machinery doesn't play nicely with the Bar's
// own hosting window; see BarTooltip.qml, which exists specifically
// as a PopupWindow-based workaround for that case).
// Usage: StyledToolTip { visible: hover.hovered; text: "..." }
ToolTip {
    id: root

    delay: 200
    y: parent.height + 15
    x: (parent.width - width) / 2

    padding: 6
    leftPadding: 12
    rightPadding: 12

    contentItem: Text {
        text: root.text
        color: Theme.selected
        font.family: Theme.fontName
        font.pixelSize: 14
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }

    background: Rectangle {
        color: Theme.backgroundAlt
        border.color: Theme.borderColor
        border.width: 1
        radius: 8

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
    }
}
