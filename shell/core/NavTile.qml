import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool ready: true
    property string subLabel: ""

    // New — same loader-circle + explicit-rotation-reset pattern as
    // IconButton's own spinning fix (raw icons look wrong mid-
    // rotation since most have an inherent up/down orientation, and a
    // RotationAnimator just freezes wherever it was when stopped
    // otherwise — loader-circle has neither problem). Also disables
    // interaction while true, same as `ready: false` but visually
    // distinct (spinner vs. the sublabel-explanation look).
    property bool loading: false

    property color hoverColor: Theme.selected
    property color activeColor: Theme.selected
    property bool isActive: false
    property real uiScale: 1.0

    readonly property bool isHovered: hover.hovered
    readonly property bool _interactive: root.ready && !root.loading

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
            id: iconItem
            icon: root.loading ? "loader-circle" : root.icon
            size: 15 * root.uiScale
            visible: root.icon !== "" || root.loading
            color: root.isActive ? Theme.backgroundAlt : root.isHovered && root.ready ? root.hoverColor : Theme.foreground
            Behavior on color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }

            NumberAnimation {
                target: iconItem
                property: "rotation"
                from: 0
                to: 360
                duration: 900
                loops: Animation.Infinite
                running: root.loading
                // Same fix as IconButton's spinning — RotationAnimator
                // runs on the render thread and doesn't reliably
                // synchronize with a direct GUI-thread property write,
                // which is what made the icon come back upside-down
                // sometimes. Plain NumberAnimation + reset in its own
                // onRunningChanged (guaranteed to fire only after it has
                // actually stopped) removes that race entirely.
                onRunningChanged: {
                    if (!running)
                        iconItem.rotation = 0;
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
        enabled: root._interactive
        cursorShape: root._interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    TapHandler {
        enabled: root._interactive
        onTapped: root.tapped()
    }
}
