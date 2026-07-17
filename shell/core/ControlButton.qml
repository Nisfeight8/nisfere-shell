import QtQuick
import QtQuick.Layouts
import qs.core

GlassCard {
    id: root

    property bool hasMore: false
    property string iconText: ""
    property bool isActive: false
    property string subtitle: "Subtitle"
    property string title: "Title"

    signal clicked
    signal moreClicked

    Layout.fillWidth: true
    Layout.preferredHeight: 70

    readonly property bool isHovered: cardHover.hovered

    // Whole-card hover tint — safe to span the full area since hover is
    // a continuous visual state (both zones lighting up together is
    // fine), unlike TAP which we zone-split below to avoid double-firing.
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.isActive ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.07) : root.isHovered ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.04) : "transparent"
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }
    HoverHandler {
        id: cardHover
        cursorShape: root.isHovered ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // ── Main clickable zone — icon badge + text ONLY. Does not
        // extend under the chevron, so there's zero pixel overlap with
        // its TapHandler — no double-fire possible, regardless of any
        // PointerHandler grab semantics (which don't block ancestors
        // the way old MouseArea bubbling did).
        RowLayout {
            id: mainZone
            Layout.fillWidth: true
            spacing: 12

            TapHandler {
                onTapped: root.clicked()
            }

            Rectangle {
                width: 42
                height: 42
                radius: 21
                color: root.isActive ? Theme.selected : Theme.backgroundAlt
                border.width: root.isActive ? 0 : 1
                border.color: Theme.borderColor
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
                    icon: root.iconText
                    size: 19
                    color: root.isActive ? Theme.background : Theme.foreground
                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: root.isActive ? Theme.selected : Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    opacity: root.isActive ? 0.85 : 0.55
                    elide: Text.ElideRight
                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }
                }
            }
        }

        // ── More chevron — separate, non-overlapping zone ─────────
        IconButton {
            visible: root.hasMore
            icon: "chevron-right"
            size: 30
            iconSize: 17
            normalColor: "transparent"
            onTapped: root.moreClicked()
        }
    }
}
