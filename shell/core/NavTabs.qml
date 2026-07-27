import QtQuick
import QtQuick.Layouts
import qs.core

// Horizontal top-tab bar with an animated underline indicator.
// NOTE: when embedding this in a Layout, size it with
// `Layout.preferredHeight`, not a raw `height:` — a RowLayout's own
// height property doesn't reliably constrain fillHeight children the
// way Layout.preferredHeight does.
RowLayout {
    id: root
    property var tabModel: []
    property int currentIndex: 0

    signal tabClicked(int tabIndex)

    spacing: 10

    Repeater {
        model: root.tabModel

        delegate: Item {
            property bool isHovered: tabHover.hovered
            property bool isSelected: root.currentIndex === index

            Layout.fillWidth: true
            // NOTE: fillHeight removed — this widget is meant to be a
            // slim, fixed-height tab bar (sized via the parent's
            // Layout.preferredHeight), not something that should stretch
            // to consume whatever vertical space is available.
            implicitHeight: content.implicitHeight + 12

            RowLayout {
                id: content
                anchors.centerIn: parent
                spacing: 8

                LucideIcon {
                    icon: modelData.icon
                    size: 18
                    color: isSelected ? Theme.selected : Theme.foreground
                    opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.4)
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

                Text {
                    text: modelData.title
                    color: isSelected ? Theme.selected : Theme.foreground
                    font.bold: isSelected
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.4)
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
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.selected
                height: 3
                radius: 2
                opacity: isSelected ? 1 : 0
                width: isSelected ? parent.width * 0.6 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
                // Deliberately NOT using Anim here — Easing.OutBack's
                // overshoot-then-settle "pop" has no equivalent among
                // our M3 bezier curves (none of them overshoot past
                // their target), so forcing this through Anim would
                // lose the underline's distinctive snap. Keep as a
                // raw NumberAnimation on purpose.
                Behavior on width {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                    }
                }
            }

            HoverHandler {
                id: tabHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: root.tabClicked(index)
            }
        }
    }
}
