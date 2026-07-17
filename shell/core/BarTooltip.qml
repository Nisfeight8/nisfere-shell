import QtQuick
import Quickshell
import qs.core

// Tooltip for items INSIDE the bar. Unlike StyledToolTip (which works
// fine in Drawers — those PanelWindows are tall enough to contain a
// normal Popup rendering below its trigger item), the bar's own
// PanelWindow is only Theme.barHeight tall. A QtQuick.Controls Popup/
// ToolTip can only ever paint within its own hosting window's bounds —
// so trying to show one "below the bar" fails, since there's no "below"
// inside a window that IS the bar's height.
//
// PopupWindow (Quickshell's own type, not QtQuick.Controls.Popup) opens
// a genuinely separate top-level window instead, free of that
// constraint — same mechanism BarPopup already uses. This reuses
// PopupContainer so it's visually/motion-consistent with everything else.
//
// Usage (from inside Bar.qml's scope, where `myBar` id is in scope):
//   BarTooltip {
//       showPopup: hoverHandler.hovered && tooltipText !== ""
//       targetItem: root
//       text: tooltipText
//   }
PopupWindow {
    id: root

    property string text: ""
    required property bool showPopup
    required property Item targetItem

    property real targetX: targetItem.mapToItem(null, 0, 0).x + (targetItem.width / 2) - (root.width / 2)
    
    
    anchor.rect.x: Math.max(8, targetX)
    anchor.rect.y: Theme.barHeight
    anchor.window: myBar

    color: "transparent"
    implicitWidth: container.implicitWidth
    implicitHeight: container.implicitHeight
    visible: showPopup || container.opacity > 0

    PopupContainer {
        id: container

        opacity: root.showPopup ? 1 : 0
        y: root.showPopup ? 0 : -10

        Text {
            text: root.text
            color: Theme.selected
            font.family: Theme.fontName
            font.pixelSize: 14
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
        }
    }
}
