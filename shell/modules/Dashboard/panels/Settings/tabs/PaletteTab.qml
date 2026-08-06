import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// Read-only palette view — no write actions here at all, just a
// live-reactive display of whatever's currently in ThemeState.shared.
// Deliberately not editable: these are all computed/derived from the
// current wallpaper or static theme, overwritten wholesale on the
// next theme change (see the daemon-side StateManager._PALETTE_KEYS
// reasoning) — a settings UI treating them as durable editable
// fields would just confuse people when a wallpaper switch quietly
// wipes their edits.
Item {
    id: root

    readonly property var shared: ThemeState.shared

    readonly property var specialColors: [
        {
            key: "background",
            label: "Background"
        },
        {
            key: "foreground",
            label: "Foreground"
        },
        {
            key: "backgroundAlt",
            label: "Background Alt"
        },
        {
            key: "foregroundAlt",
            label: "Foreground Alt"
        },
        {
            key: "accent",
            label: "Accent"
        },
        {
            key: "cursor",
            label: "Cursor"
        },
        {
            key: "borderColor",
            label: "Border"
        },
    ]

    readonly property string _sourceLabel: ThemeState.sourceType === "static" ? "Static Theme" : "Dynamic (Wallpaper)"
    readonly property string _sourceValue: ThemeState.sourceType === "static" ? (ThemeState.sourceName || "—") : (ThemeState.wallpaper ? ThemeState.wallpaper.split("/").pop() : "—")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ── Current source info ──────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            InfoRow {
                Layout.fillWidth: true
                label: "Source"
                value: root._sourceLabel
                valueColor: Theme.selected
            }
            InfoRow {
                Layout.fillWidth: true
                label: ThemeState.sourceType === "static" ? "Theme" : "Wallpaper"
                value: root._sourceValue
            }
            InfoRow {
                Layout.fillWidth: true
                label: "Mode"
                value: ThemeState.mode === "dark" ? "Dark" : "Light"
            }
        }

        InfoDivider {}

        // ── 16-color palette ──────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Palette"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13
                font.bold: true
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 8
                rowSpacing: 12
                columnSpacing: 8

                Repeater {
                    model: 16

                    delegate: ColumnLayout {
                        required property int index
                        readonly property string hex: root.shared["color" + index] ?? "#000000"

                        spacing: 4

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignHCenter
                            radius: Theme.radius / 2
                            color: parent.hex
                            border.width: 1
                            border.color: Theme.borderColor
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: index
                            color: Theme.foreground
                            opacity: 0.6
                            font.family: Theme.fontName
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        InfoDivider {}

        // ── Special colors ────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Special"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13
                font.bold: true
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 14
                columnSpacing: 12

                Repeater {
                    model: root.specialColors

                    delegate: ColumnLayout {
                        required property var modelData
                        readonly property string hex: root.shared[modelData.key] ?? "#000000"

                        spacing: 4

                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            Layout.alignment: Qt.AlignHCenter
                            radius: Theme.radius / 2
                            color: parent.hex
                            border.width: 1
                            border.color: Theme.borderColor
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.label
                            color: Theme.foreground
                            opacity: 0.75
                            font.family: Theme.fontName
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: hex
                            color: Theme.foreground
                            opacity: 0.4
                            font.family: Theme.fontName
                            font.pixelSize: 9
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
