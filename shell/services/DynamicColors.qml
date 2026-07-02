pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ── Metadata ───────────────────────────────────────────────
    property string wallpaper: ""
    property string mode: "dark"
    property string sourceType: "dynamic"  // "dynamic" | "static"
    property string sourceName: ""         // "" if dynamic, theme name if static

    // ── Defaults: Catppuccin Mocha ─────────────────────────────
    // Used until state.json loads (startup) or if load fails
    property color background: "#1e1e2e"
    property color backgroundAlt: "#252535"
    property color foreground: "#cdd6f4"
    property color cursor: "#cdd6f4"
    property color borderColor: "#313244"
    property color selected: "#cba6f7"  // = color5 (accent)

    property color color0: "#45475a"
    property color color1: "#f38ba8"
    property color color2: "#a6e3a1"
    property color color3: "#f9e2af"
    property color color4: "#89b4fa"
    property color color5: "#cba6f7"
    property color color6: "#94e2d5"
    property color color7: "#bac2de"
    property color color8: "#585b70"
    property color color9: "#f38ba8"
    property color color10: "#a6e3a1"
    property color color11: "#f9e2af"
    property color color12: "#89b4fa"
    property color color13: "#cba6f7"
    property color color14: "#94e2d5"
    property color color15: "#a6adc8"

    // ── FileView ───────────────────────────────────────────────
    // Watches ~/.cache/nisfere/state.json directly.
    // No socket dependency: daemon writes the file → FileView picks it up.
    property FileView _cache: FileView {
        path: Quickshell.env("HOME") + "/.cache/nisfere/state.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root._applyState(JSON.parse(text()));
            } catch (e) {
                console.warn("DynamicColors: Parse error:", e);
            }
        }
        onLoadFailed: console.warn("DynamicColors: state.json not found, using defaults")
    }

    // ── Apply state ────────────────────────────────────────────
    // state.json structure (new):
    // {
    //   wallpaper: str, mode: str, source_type: str, source_name: str|null,
    //   colors: { background, foreground, cursor, background_alt,
    //             border_color, color0..color15, ... }
    // }
    function _applyState(state) {
        // Top-level metadata
        if (state.wallpaper)
            root.wallpaper = state.wallpaper;
        if (state.mode)
            root.mode = state.mode;
        if (state.source_type)
            root.sourceType = state.source_type;
        root.sourceName = state.source_name ?? "";
        let c = state.colors ?? {};

        if (c.background)
            root.background = c.background;
        if (c.foreground)
            root.foreground = c.foreground;
        if (c.cursor)
            root.cursor = c.cursor;
        if (c.background_alt)
            root.backgroundAlt = c.background_alt;
        if (c.border_color)
            root.borderColor = c.border_color;

        // selected = color5 (accent in most wallust palettes)
        if (c.color4)
            root.selected = c.color4;

        if (c.color0)
            root.color0 = c.color0;
        if (c.color1)
            root.color1 = c.color1;
        if (c.color2)
            root.color2 = c.color2;
        if (c.color3)
            root.color3 = c.color3;
        if (c.color4)
            root.color4 = c.color4;
        if (c.color5)
            root.color5 = c.color5;
        if (c.color6)
            root.color6 = c.color6;
        if (c.color7)
            root.color7 = c.color7;
        if (c.color8)
            root.color8 = c.color8;
        if (c.color9)
            root.color9 = c.color9;
        if (c.color10)
            root.color10 = c.color10;
        if (c.color11)
            root.color11 = c.color11;
        if (c.color12)
            root.color12 = c.color12;
        if (c.color13)
            root.color13 = c.color13;
        if (c.color14)
            root.color14 = c.color14;
        if (c.color15)
            root.color15 = c.color15;
    }
}
