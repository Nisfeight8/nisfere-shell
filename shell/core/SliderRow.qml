import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root

    property string activeIcon: "volume-2"
    property string mutedIcon: "volume-x"
    property bool isMuteable: false
    property bool isMuted: false

    property real value: 0.0
    property string valueText: (root.isMuteable && root.isMuted) ? "Mute" : Math.round(internalSlider.value * 100) + "%"

    signal toggleMuteClicked
    signal liveValueMoved(real newValue)
    signal finalValueChanged(real newValue)

    Layout.fillWidth: true
    spacing: 12

    Rectangle {
        border.color: (root.isMuteable && root.isMuted) ? Theme.borderColor : "transparent"
        color: (root.isMuteable && root.isMuted) ? Theme.backgroundAlt : "transparent"
        height: 36
        radius: 18
        width: 36

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
            size: 18
            color: (root.isMuteable && root.isMuted) ? Theme.foreground : Theme.selected
            opacity: (root.isMuteable && root.isMuted) ? 0.5 : 1.0
            icon: root.isMuted ? root.mutedIcon : root.activeIcon

            Behavior on color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }
            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }
        }

        HoverHandler {
            enabled: root.isMuteable
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            enabled: root.isMuteable
            onTapped: root.toggleMuteClicked()
        }
    }

    ControlSlider {
        id: internalSlider
        Layout.fillWidth: true
        isMuted: root.isMuteable && root.isMuted

        // Was a plain `value: root.value` binding — the FIRST time the
        // user drags the slider, Slider's own internal drag handling
        // writes to `value` imperatively, silently destroying a plain
        // declarative binding. After that this slider would stop
        // following root.value if it ever changed externally (e.g.
        // volume changed by a hardware key while this panel is open).
        // Same bug MediaSlider.qml already correctly avoids — using
        // the same Binding + when:!pressed pattern here too.
        Binding {
            target: internalSlider
            property: "value"
            value: root.value
            when: !internalSlider.pressed
            restoreMode: Binding.RestoreNone
        }

        onMoved: root.liveValueMoved(internalSlider.value)
        onPressedChanged: if (!pressed)
            root.finalValueChanged(internalSlider.value)
    }

    Text {
        Layout.preferredWidth: 35
        color: Theme.foreground
        font.pixelSize: 12
        horizontalAlignment: Text.AlignRight
        opacity: 0.7
        text: root.valueText
    }
}
