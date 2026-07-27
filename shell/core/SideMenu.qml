import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root

    property var menuModel: []
    property int currentIndex: 0
    signal tabClicked(int tabIndex)
    implicitWidth: 220

    ListView {
        anchors.fill: parent
        model: root.menuModel
        spacing: 5
        clip: true
        // Was interactive: false (fine when this only ever held a
        // handful of items, e.g. Productivity's 2 tabs). Now also used
        // for the launcher's Apps sub-tabs, which can have well over a
        // dozen entries (All/Favorites/Most Used/Recent + every
        // category) — needs to actually scroll. Backward compatible:
        // when content already fits (the original small-list case),
        // enabling interactive scrolling changes nothing visually.
        interactive: true

        delegate: Item {
            width: ListView.view.width
            height: 45

            property bool isHovered: itemHover.hovered
            property bool isSelected: root.currentIndex === index

            Rectangle {
                anchors.fill: parent
                color: Theme.foreground
                opacity: isHovered && !isSelected ? 0.05 : 0
                radius: Theme.radius
                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                spacing: 12

                LucideIcon {
                    icon: modelData.icon
                    size: 18
                    color: isSelected ? Theme.selected : Theme.foreground
                    opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.4)

                    Behavior on color {
                        AnimColor {
                            type: Anim.DefaultEffects
                        }
                    }
                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: modelData.title
                    color: isSelected ? Theme.selected : Theme.foreground
                    font.bold: isSelected
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.4)

                    Behavior on color {
                        AnimColor {
                            type: Anim.DefaultEffects
                        }
                    }
                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.selected
                width: 3
                radius: 2
                opacity: isSelected ? 1 : 0
                height: isSelected ? parent.height * 0.5 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
                // Deliberately NOT using Anim here — same reasoning as
                // NavTabs' underline: Easing.OutBack's overshoot-then-
                // settle "pop" has no equivalent among our M3 bezier
                // curves, so this stays a raw NumberAnimation on purpose.
                Behavior on height {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                    }
                }
            }

            HoverHandler {
                id: itemHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: root.tabClicked(index)
            }
        }
    }
}
