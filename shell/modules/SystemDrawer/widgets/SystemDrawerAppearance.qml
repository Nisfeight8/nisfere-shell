import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
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

            Rectangle {
                width: 90
                height: 56
                radius: 8
                color: Theme.backgroundAlt
                clip: true   // safety net — doesn't round the image itself, see below

                // Hidden — only used as texture source for OpacityMask
                Image {
                    id: wallpaperThumb
                    anchors.fill: parent
                    source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }
                Rectangle {
                    id: wallpaperThumbMask
                    anchors.fill: wallpaperThumb
                    radius: 8
                    visible: false
                }
                // clip:true only clips to the rectangular bounds, not the rounded
                // shape — since the image (PreserveAspectCrop) exactly fills the
                // whole rectangle, its square corners would still show past the
                // radius curve without this mask.
                OpacityMask {
                    anchors.fill: wallpaperThumb
                    source: wallpaperThumb
                    maskSource: wallpaperThumbMask
                }

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

        // ── Quick-action tiles ─────────────────────────────────────
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 6
            columnSpacing: 6

            NavTile {
                Layout.fillWidth: true
                icon: "layout-grid"
                label: "App Launcher"
                onTapped: {
                    ShellState.appLauncherOpened = true;
                }
            }

            NavTile {
                Layout.fillWidth: true
                icon: "image"
                label: "Wallpapers"
                onTapped: {
                    ShellState.quickActionsOpened = true;
                    ShellState.quickAction = "wallpaper";
                }
            }

            NavTile {
                Layout.fillWidth: true
                icon: "palette"
                label: "Themes"
                onTapped: {
                    ShellState.quickActionsOpened = true;
                    ShellState.quickAction = "colors";
                }
            }

            // Was `ready: false` / "Coming soon" — the feature already
            // exists (see SystemStatsWidget.qml's own "Full System
            // Monitor" NavTile), just wasn't wired up here yet. Same
            // destination, same wiring.
            NavTile {
                Layout.fillWidth: true
                icon: "activity"
                label: "System Monitor"
                onTapped: {
                    ShellState.appLauncherOpened = true;
                    ShellState.launcherActiveTab = 1;
                    ShellState.launcherActiveTool = "sysmon";
                }
            }
        }
    }
}
