import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// Chroma extraction tuning — nisfere_chroma's 5 knobs (algorithm +
// 4 sliders). Reads from ThemeState.chromaSettings, writes via
// ThemeActions.setChromaSetting() — the daemon live-reapplies colors
// from the current wallpaper automatically if one's active (see
// ThemeManager.set_chroma_setting), so changes here are felt
// immediately without needing any "Apply" button.
Item {
    id: root

    readonly property var chroma: ThemeState.chromaSettings

    readonly property var algorithms: [
        {
            key: "median_cut",
            label: "Median Cut"
        },
        {
            key: "octree",
            label: "Octree"
        },
        {
            key: "kmeans",
            label: "K-Means"
        },
        {
            key: "histogram",
            label: "Histogram"
        },
    ]

    // Debounces slider drags — sends at most one setChromaSetting()
    // call ~300ms after the last movement, instead of one per pixel
    // dragged. Each call makes the daemon re-run color extraction
    // against the current wallpaper (fine occasionally, wasteful
    // dozens of times a second mid-drag, especially with the slower
    // algorithms like kmeans).
    property string _pendingKey: ""
    property var _pendingValue: null
    property Timer _debounceTimer: Timer {
        interval: 300
        repeat: false
        onTriggered: ThemeActions.setChromaSetting(root._pendingKey, root._pendingValue)
    }
    function _debouncedSet(key, value) {
        root._pendingKey = key;
        root._pendingValue = value;
        root._debounceTimer.restart();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 24

        // ── Info banner ──────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: noticeRow.implicitHeight + 20
            radius: Theme.radius
            color: Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.25)

            RowLayout {
                id: noticeRow
                anchors {
                    fill: parent
                    margins: 10
                }
                spacing: 10

                LucideIcon {
                    icon: "info"
                    size: 16
                    color: Theme.selected
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: "These settings only take visible effect when your theme is set to extract colors from a wallpaper (dynamic mode). If you're currently using a static theme, changes here are saved but won't show until you switch to a wallpaper-based theme."
                    color: Theme.foreground
                    opacity: 0.85
                    font.family: Theme.fontName
                    font.pixelSize: 12
                }
            }
        }

        // ── Algorithm ────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Algorithm"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.algorithms

                    delegate: NavTile {
                        required property var modelData
                        Layout.fillWidth: true
                        label: modelData.label
                        isActive: root.chroma.algorithm === modelData.key
                        onTapped: ThemeActions.setChromaSetting("algorithm", modelData.key)
                    }
                }
            }
        }

        InfoDivider {}

        // ── Saturation ───────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Saturation"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13
                }
                Text {
                    text: saturationSlider.value.toFixed(2)
                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }
            }
            CustomSlider {
                id: saturationSlider
                Layout.fillWidth: true
                from: 0.0
                to: 2.5
                value: root.chroma.saturation ?? 1.3
                onMoved: root._debouncedSet("saturation", value)
            }
        }

        // ── Background saturation ──────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Background Saturation"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13
                }
                Text {
                    text: bgSaturationSlider.value.toFixed(2)
                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }
            }
            CustomSlider {
                id: bgSaturationSlider
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                value: root.chroma.bg_saturation ?? 0.08
                onMoved: root._debouncedSet("bg_saturation", value)
            }
        }

        // ── Contrast ─────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Contrast"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13
                }
                Text {
                    text: contrastSlider.value.toFixed(2)
                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }
            }
            CustomSlider {
                id: contrastSlider
                Layout.fillWidth: true
                // Capped at 2.0 — deliberately well below the point
                // where 0.35^contrast collapses background/foreground
                // onto the lightness floor/ceiling regardless of the
                // actual wallpaper (hit this exact issue at
                // contrast=3.55 earlier). Below 2.0, contrast still
                // behaves proportionally to the image.
                from: 0.5
                to: 2.0
                value: root.chroma.contrast ?? 1.0
                onMoved: root._debouncedSet("contrast", value)
            }
        }

        InfoDivider {}

        // ── Sample resolution ────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Sample Resolution"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13
                }
                Text {
                    text: Math.round(resizeSlider.value) + "px"
                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }
            }
            CustomSlider {
                id: resizeSlider
                Layout.fillWidth: true
                from: 50
                to: 500
                stepSize: 10
                value: root.chroma.resize_to ?? 200
                onMoved: root._debouncedSet("resize_to", Math.round(value))
            }
            Text {
                Layout.fillWidth: true
                text: "Higher = more accurate sampling, slower extraction"
                color: Theme.foreground
                opacity: 0.45
                font.family: Theme.fontName
                font.pixelSize: 11
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
