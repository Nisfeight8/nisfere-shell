import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "tabs"

// Settings — top-level container: a SideMenu of category tabs on the
// left, the selected tab's own content on the right (Appearance,
// Hyprland, Chroma, Palette, Wallpapers, Theme Source — all wired in).
Item {
    id: root

    // Fixed, deliberate size — NOT derived from whichever tab happens
    // to be selected. Settings is a standalone top-level Dashboard
    // component now (see ShellState.dashboardActiveComponent), not
    // part of TabsComponent's floor/ceiling system, so nothing else
    // protects it from collapsing: this root previously had NO
    // implicit size at all, meaning DashboardContent's AnimLoader saw
    // 0×0 and the whole drawer panel shrank to its bare minimum
    // (Dashboard.qml's minPanelWidth: 250) whenever Settings opened.
    //
    // A fixed size here also matches how every settings dialog you've
    // ever used behaves — the window doesn't resize when you switch
    // from "Appearance" to "Wallpapers"; tune these two numbers to
    // whichever tab needs the most room (probably Wallpapers, with
    // thumbnails, or Chroma/Palette with sliders+swatches), not to an
    // average.
    implicitWidth: 760
    implicitHeight: 560

    anchors.fill: parent

    // One entry per settings category. Icons are LucideIcon names
    // (see assets/icons/) — swap freely, these are just reasonable
    // first picks per category, not final.
    readonly property var tabModel: [
        {
            icon: "palette",
            title: "Appearance",
            key: "appearance"
        },
        {
            icon: "layout-grid",
            title: "Hyprland",
            key: "hyprland"
        },
        {
            icon: "sliders-vertical",
            title: "Chroma",
            key: "chroma"
        },
        {
            icon: "swatch-book",
            title: "Palette",
            key: "palette"
        },
        {
            icon: "image",
            title: "Wallpapers",
            key: "wallpapers"
        },
        {
            // TEMPORARY icon/title — this tab is a stopgap (Mode +
            // Static Themes only, wallpaper picker moved out) until
            // it becomes a dedicated "Colors" tab in the next step.
            icon: "paintbrush",
            title: "Theme Source",
            key: "source"
        },
    ]

    property int currentIndex: 0
    readonly property var currentTab: root.tabModel[root.currentIndex] ?? null
    readonly property string currentKey: root.currentTab ? root.currentTab.key : ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Own small row, entirely separate from SideMenu+content below
        // — just the X, right-aligned. Same reasoning as
        // DockerManager's fix: keeping it fully separate avoids any
        // risk of overlapping whatever a given tab (Appearance/
        // Hyprland/Chroma/Palette/Wallpapers/Theme Source) has in its
        // own top-right corner.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            Item {
                Layout.fillWidth: true
            }

            // Same "X" convention as DockerManager/SystemMonitorTool —
            // ShellState.closeResumableComponent() both closes the
            // dashboard AND forgets this as the backgrounded/resumable
            // tool.
            IconButton {
                icon: "x"
                size: 28
                iconSize: 13
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.color1
                tooltipText: "Close"
                onTapped: ShellState.closeResumableComponent()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            SideMenu {
                Layout.fillHeight: true
                menuModel: root.tabModel
                currentIndex: root.currentIndex
                onTabClicked: index => root.currentIndex = index
            }

            // ── Content area — one Loader per tab, keyed on currentKey ──
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    anchors.fill: parent
                    active: root.currentKey === "chroma"
                    visible: active
                    sourceComponent: Component {
                        ChromaTab {}
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: root.currentKey === "palette"
                    visible: active
                    sourceComponent: Component {
                        PaletteTab {}
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: root.currentKey === "hyprland"
                    visible: active
                    sourceComponent: Component {
                        HyprlandTab {}
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: root.currentKey === "appearance"
                    visible: active
                    sourceComponent: Component {
                        AppearanceTab {}
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: root.currentKey === "wallpapers"
                    visible: active
                    sourceComponent: Component {
                        WallpapersTab {}
                    }
                }
                Loader {
                    anchors.fill: parent
                    active: root.currentKey === "source"
                    visible: active
                    sourceComponent: Component {
                        ThemeSourceTab {}
                    }
                }
            }
        }
    }
}
