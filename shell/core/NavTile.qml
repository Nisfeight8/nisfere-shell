import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool ready: true
    property string subLabel: ""

    property color hoverColor: Theme.selected
    property color activeColor: Theme.selected
    property bool isActive: false
    property real uiScale: 1.0

    readonly property bool isHovered: hover.hovered

    signal tapped

    implicitHeight: 36 * uiScale
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
        width: Math.max(0, Math.min(implicitWidth, root.width - (16 * root.uiScale)))
        spacing: 7 * root.uiScale

        LucideIcon {
            icon: root.icon
            size: 15 * root.uiScale
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
                font.pixelSize: 13 * root.uiScale
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
                font.pixelSize: 9 * root.uiScale
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
