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
    property real uiScale: 1.0

    // Fixed, deliberate size — NOT derived from whichever tab happens
    // to be selected (see original reasoning below). Scaled by uiScale
    // so this dialog-style panel gets proportionally more room on
    // higher-res screens rather than staying pinned at a 1080p size —
    // internal tab content (Appearance/Hyprland/Chroma/etc.) is left
    // unscaled deliberately: already verified to render correctly
    // across screen sizes, so only the outer window size needs to
    // track uiScale here, not every internal value.
    implicitWidth: 760 * uiScale
    implicitHeight: 560 * uiScale

    anchors.fill: parent

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
        spacing: 10 * root.uiScale

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28 * root.uiScale

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                icon: "x"
                size: 28 * root.uiScale
                iconSize: 13 * root.uiScale
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
            spacing: 10 * root.uiScale

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
