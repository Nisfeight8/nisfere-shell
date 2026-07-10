import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 10

        // ── Wallpaper + theme info ────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Wallpaper thumbnail — larger
            Rectangle {
                width: 90
                height: 56
                radius: 8
                color: Theme.backgroundAlt
                clip: true

                Image {
                    anchors.fill: parent
                    source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                // Subtle border overlay
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.borderColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                RowLayout {
                    spacing: 6
                    LucideIcon {
                        icon: "image"
                        size: 13
                        color: Theme.selected
                    }
                    Text {
                        text: Theme.wallpaper ? Theme.wallpaper.split("/").pop().replace(/\.[^.]+$/, "") : "No wallpaper"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                RowLayout {
                    spacing: 6
                    LucideIcon {
                        icon: "palette"
                        size: 13
                        color: Theme.selected
                    }
                    Text {
                        text: Theme.sourceType === "static" ? Theme.sourceName + " · " + Theme.mode : "Dynamic · " + Theme.mode
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 12
                        opacity: 0.75
                    }
                }
            }
        }

        // ── Quick-action buttons ──────────────────────────────────
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 6
            columnSpacing: 6

            Repeater {
                model: [
                    {
                        icon: "layout-grid",
                        label: "App Launcher",
                        state: "launcher"
                    },
                    {
                        icon: "image",
                        label: "Wallpapers",
                        state: "wallpapers"
                    },
                    {
                        icon: "palette",
                        label: "Themes",
                        state: "themes"
                    },
                    {
                        icon: "sparkles",
                        label: "Appearance",
                        state: "appearance"
                    },
                ]

                Rectangle {
                    id: btn
                    property bool isHovered: false

                    Layout.fillWidth: true
                    height: 36
                    radius: 8

                    color: isHovered ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15) : Theme.backgroundAlt
                    border.width: isHovered ? 1 : 1
                    border.color: isHovered ? Theme.selected : Theme.borderColor

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 7

                        LucideIcon {
                            icon: modelData.icon
                            size: 15
                            color: btn.isHovered ? Theme.selected : Theme.foreground
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }
                        Text {
                            text: modelData.label
                            color: btn.isHovered ? Theme.selected : Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: btn.isHovered = hovered
                    }
                    TapHandler {
                        onTapped: {
                            switch (modelData.state) {
                            case "launcher":
                                ShellState.launcherOpened = false;
                                ShellState.appLauncherOpened = true;
                                break;
                            default:
                                ShellState.controlCenterOpened = true;
                                ShellState.controlCenterTab = modelData.state;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
}
