import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.core
import qs.services

// Wallpaper picker — searchable grid, plus a toggle for whether
// picking a new wallpaper also re-extracts/applies colors dynamically
// from it (apply_colors) or just changes the background image while
// leaving whatever color source (static theme or a previous
// wallpaper's palette) already active untouched.
//
// NOTE: the toggle's state is session-local (resets to true — the
// previous always-on default — each time Settings is reopened), not
// persisted to state.json. Nothing in the daemon currently has a slot
// for "remember this preference" the way chroma_settings/style do —
// easy to add later if you want it to stick across sessions, just
// didn't want to invent a new state.json field for this without
// discussing it first.
Item {
    id: root

    property string _wallpaperSearch: ""
    property bool extractDynamicColors: true

    readonly property var filteredWallpapers: {
        if (root._wallpaperSearch === "")
            return ThemeActions.wallpapers;
        const q = root._wallpaperSearch.toLowerCase();
        return ThemeActions.wallpapers.filter(w => w.name.toLowerCase().includes(q));
    }

    Component.onCompleted: ThemeActions.fetchWallpapers()

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 24

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
            }

            // ── Mode ─────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                Text {
                    Layout.fillWidth: true
                    text: "Light Mode"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }
                ToggleSwitch {
                    checked: ThemeState.mode === "light"
                    onToggled: ThemeActions.toggleMode()
                }
            }

            InfoDivider {
                Layout.leftMargin: 20
                Layout.rightMargin: 20
            }

            // ── Extract Dynamic Colors toggle ────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Extract Dynamic Colors"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "When on, picking a wallpaper below also re-extracts and applies its colors. When off, only the background image changes — your current color theme stays as-is."
                        color: Theme.foreground
                        opacity: 0.5
                        font.family: Theme.fontName
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                    }
                }
                ToggleSwitch {
                    checked: root.extractDynamicColors
                    onToggled: root.extractDynamicColors = !checked
                }
            }

            InfoDivider {
                Layout.leftMargin: 20
                Layout.rightMargin: 20
            }

            // ── Wallpaper grid ────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                SearchBar {
                    Layout.fillWidth: true
                    placeholderText: "Search wallpapers..."
                    onTextChanged: root._wallpaperSearch = text
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.filteredWallpapers.length === 0
                    text: ThemeActions.wallpapers.length === 0 ? "No wallpapers found" : "No matches"
                    color: Theme.foreground
                    opacity: 0.4
                    font.family: Theme.fontName
                    font.pixelSize: 12
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: root.filteredWallpapers

                        delegate: ColumnLayout {
                            required property var modelData
                            readonly property bool isSelected: ThemeState.sourceType === "dynamic" && ThemeState.wallpaper === modelData.path

                            spacing: 4
                            width: 110

                            Rectangle {
                                id: card
                                Layout.preferredWidth: 110
                                Layout.preferredHeight: 70
                                radius: Theme.radius
                                color: Theme.backgroundAlt
                                border.width: isSelected ? 2 : 1
                                border.color: isSelected ? Theme.selected : Theme.borderColor

                                // Hidden — only used as texture source
                                // for OpacityMask. clip:true alone only
                                // clips to the rectangular bounds, not
                                // the rounded shape — since the image
                                // (PreserveAspectCrop) exactly fills
                                // the whole rectangle, its square
                                // corners would still show past the
                                // radius curve without this mask.
                                Image {
                                    id: wpImage
                                    anchors.fill: parent
                                    anchors.margins: card.border.width
                                    source: "file://" + modelData.path
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: false
                                }
                                Rectangle {
                                    id: wpImageMask
                                    anchors.fill: wpImage
                                    radius: parent.radius
                                    visible: false
                                }
                                OpacityMask {
                                    anchors.fill: wpImage
                                    source: wpImage
                                    maskSource: wpImageMask
                                }

                                HoverHandler {
                                    id: wpHover
                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    onTapped: ThemeActions.setWallpaper(modelData.path, root.extractDynamicColors, ThemeState.mode)
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: Theme.selected
                                    opacity: wpHover.hovered && !isSelected ? 0.12 : 0
                                    Behavior on opacity {
                                        Anim {
                                            type: Anim.FastEffects
                                        }
                                    }
                                }
                            }
                            Text {
                                Layout.preferredWidth: 110
                                text: modelData.name
                                color: isSelected ? Theme.selected : Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 12
            }
        }
    }
}
