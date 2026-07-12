import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// Appearance panel: Wallpapers (top, horizontal) + Themes (bottom, list)
// Sub-tabs let the user switch between the two
Item {
    id: root

    property int _activeTab: 0   // 0=Wallpapers, 1=Themes

    property string searchText: ""

    implicitHeight: 440
    implicitWidth: 520

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ── Sub-tabs ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    {
                        icon: "image",
                        label: "Wallpapers"
                    },
                    {
                        icon: "palette",
                        label: "Themes"
                    },
                ]

                Rectangle {
                    id: subTab

                    property bool isActive: root._activeTab === index
                    property bool isHovered: false

                    Layout.fillWidth: true
                    border.color: isActive ? Theme.selected : Theme.borderColor
                    border.width: 1
                    color: isActive ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.18) : (isHovered ? Theme.backgroundAlt : "transparent")
                    height: 30
                    radius: 8

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        LucideIcon {
                            color: subTab.isActive ? Theme.selected : Theme.foreground
                            icon: modelData.icon
                            size: 12

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }
                        }
                        Text {
                            color: subTab.isActive ? Theme.selected : Theme.foreground
                            font.bold: subTab.isActive
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            text: modelData.label

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }
                        }
                    }
                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor

                        onHoveredChanged: subTab.isHovered = hovered
                    }
                    TapHandler {
                        onTapped: root._activeTab = index
                    }
                }
            }
        }

        // ── Content ───────────────────────────────────────────────
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true

            // WallpaperPicker
            Loader {
                active: root._activeTab === 0
                anchors.fill: parent
                source: "WallpaperPicker.qml"
                visible: active
            }

            // ThemePicker
            Loader {
                active: root._activeTab === 1
                anchors.fill: parent
                source: "ThemePicker.qml"
                visible: active
            }
        }
    }
}
