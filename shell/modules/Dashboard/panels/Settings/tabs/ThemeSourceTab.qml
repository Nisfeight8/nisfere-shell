import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.core
import qs.services

// TEMPORARY shape — wallpaper picker moved out to WallpapersTab.qml.
// What's left here (Mode toggle + Static Themes grid) is a stopgap
// until this becomes a proper dedicated "Colors" tab in the next
// step — not renamed/polished yet on purpose, per the plan to do
// Wallpapers first and Colors as its own separate pass.
Item {
    id: root

    property string _themeSearch: ""

    readonly property var filteredThemes: {
        if (root._themeSearch === "")
            return ThemeActions.themes;
        const q = root._themeSearch.toLowerCase();
        return ThemeActions.themes.filter(t => t.name.toLowerCase().includes(q));
    }

    Component.onCompleted: ThemeActions.fetchThemes()

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

            // ── Static Themes ────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                Text {
                    text: "Static Themes"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }

                SearchBar {
                    Layout.fillWidth: true
                    placeholderText: "Search themes..."
                    onTextChanged: root._themeSearch = text
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.filteredThemes.length === 0
                    text: ThemeActions.themes.length === 0 ? "No themes found" : "No matches"
                    color: Theme.foreground
                    opacity: 0.4
                    font.family: Theme.fontName
                    font.pixelSize: 12
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: root.filteredThemes

                        delegate: ColumnLayout {
                            required property var modelData
                            readonly property bool isSelected: ThemeState.sourceType === "static" && ThemeState.sourceName === modelData.name

                            spacing: 4
                            width: 110

                            Rectangle {
                                id: swatchBox
                                Layout.preferredWidth: 110
                                Layout.preferredHeight: 70
                                radius: Theme.radius
                                color: modelData.colors.background ?? Theme.backgroundAlt
                                border.width: isSelected ? 2 : 1
                                border.color: isSelected ? Theme.selected : Theme.borderColor
                                clip: true

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Repeater {
                                        model: [1, 2, 3, 4, 5, 6]
                                        delegate: Rectangle {
                                            required property int modelData
                                            width: 12
                                            height: 12
                                            radius: 2
                                            color: swatchBox.parent.modelData.colors["color" + modelData] ?? "#888888"
                                        }
                                    }
                                }

                                HoverHandler {
                                    id: themeHover
                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    onTapped: ThemeActions.setColors(modelData.name, ThemeState.mode)
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: Theme.selected
                                    opacity: themeHover.hovered && !isSelected ? 0.12 : 0
                                    radius: Theme.radius
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
