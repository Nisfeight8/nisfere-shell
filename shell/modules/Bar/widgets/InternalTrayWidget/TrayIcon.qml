import QtQuick
import qs.core
import qs.services


// Simple icon(+optional info text) with a bar-appropriate tooltip.
// Uses BarTooltip (PopupWindow-based) rather than StyledToolTip —
// the bar's own PanelWindow is too short to contain a normal in-window
// Popup rendering below it; see BarTooltip.qml for the full explanation.
Item {
    id: root

    property string iconName: ""
    property string infoText: ""
    property string tooltipText: ""
    property int iconSize: 16

    implicitWidth: contentRow.implicitWidth
    implicitHeight: contentRow.implicitHeight

    Row {
        id: contentRow
        spacing: 6
        anchors.centerIn: parent

        LucideIcon {
            icon: root.iconName
            size: root.iconSize
            color: Theme.foreground
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.infoText !== ""
            text: root.infoText
            font.family: Theme.fontName
            font.pixelSize: 14
            color: Theme.foreground
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    BarTooltip {
        showPopup: hoverHandler.hovered && !ShellState.controlCenterOpened && root.tooltipText !== ""
        targetItem: root
        text: root.tooltipText
    }
}
