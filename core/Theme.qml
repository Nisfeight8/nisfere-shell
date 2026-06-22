pragma Singleton

import QtQuick

QtObject {
    // --- Layout & Styling ---
    readonly property bool enableWidgetBorders: true

    readonly property string fontName: "Arimo Nerd Font"
    readonly property int radius: 15
    readonly property int barHeight: 50
    readonly property int padding: 6

    readonly property int panelBorderSize: 10
    readonly property int widgetBorderWidth: enableWidgetBorders ? 1 : 0

    readonly property color borderColor: "#3b4261"
    readonly property color highlightBorderColor: "#7aa2f7"
    

    // --- Base Colors ---
    readonly property color background: "#1f2335"
    readonly property color backgroundAlt: "#292e42"
    readonly property color foreground: "#c0caf5"
    readonly property color selected: "#7aa2f7"

    // --- Pywal / 16 Color Palette ---
    readonly property color color0: "#3b4261"
    readonly property color color1: "#ff007c"
    readonly property color color2: "#4fd6be"
    readonly property color color3: "#ff9e64"
    readonly property color color4: "#7aa2f7"
    readonly property color color5: "#9d7cd8"
    readonly property color color6: "#7dcfff"
    readonly property color color7: "#a9b1d6"
    readonly property color color8: "#565f89"
    readonly property color color9: "#c53b53"
    readonly property color color10: "#c3e88d"
    readonly property color color11: "#ffc777"
    readonly property color color12: "#3d59a1"
    readonly property color color13: "#bb9af7"
    readonly property color color14: "#b4f9f8"
    readonly property color color15: "#737aa2"
}