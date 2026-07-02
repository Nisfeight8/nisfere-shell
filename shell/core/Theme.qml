pragma Singleton
import QtQuick
import qs.services

QtObject {

    // ── Static layout values ───────────────────────────────────
    readonly property bool enableWidgetBorders: true
    readonly property string fontName: "Arimo Nerd Font"
    readonly property int radius: 15
    readonly property int barHeight: 50
    readonly property int padding: 6
    readonly property int panelBorderSize: 10
    readonly property int widgetBorderWidth: enableWidgetBorders ? 1 : 0

    // ── Base colors → from DynamicColors ──────────────────────
    property color background: DynamicColors.background
    property color foreground: DynamicColors.foreground
    property color selected: DynamicColors.selected
    property color cursor: DynamicColors.cursor

    // ── Computed colors ────────────────────────────────────────
    // Computed in QML rather than reading from DynamicColors so
    // they respond instantly to color transitions (no file I/O).
    // The daemon also computes these (for template rendering),
    // but Qt.tint gives a more harmonious shell result.
    property color backgroundAlt: Qt.tint(background, Qt.rgba(foreground.r, foreground.g, foreground.b, 0.06))
    property color borderColor: Qt.tint(background, Qt.rgba(foreground.r, foreground.g, foreground.b, 0.14))
    property color highlightBorderColor: selected

    // ── Full palette → from DynamicColors ─────────────────────
    property color color0: DynamicColors.color0
    property color color1: DynamicColors.color1
    property color color2: DynamicColors.color2
    property color color3: DynamicColors.color3
    property color color4: DynamicColors.color4
    property color color5: DynamicColors.color5
    property color color6: DynamicColors.color6
    property color color7: DynamicColors.color7
    property color color8: DynamicColors.color8
    property color color9: DynamicColors.color9
    property color color10: DynamicColors.color10
    property color color11: DynamicColors.color11
    property color color12: DynamicColors.color12
    property color color13: DynamicColors.color13
    property color color14: DynamicColors.color14
    property color color15: DynamicColors.color15

    // ── Metadata ───────────────────────────────────────────────
    property string wallpaper: DynamicColors.wallpaper
    property string mode: DynamicColors.mode
    property string sourceType: DynamicColors.sourceType
    property string sourceName: DynamicColors.sourceName
}
