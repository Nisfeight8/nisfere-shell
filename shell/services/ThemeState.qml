pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The ONE FileView watching state.json. Colors.qml and Settings.qml
// both read from here instead of each having their own FileView on
// the same file (which would mean two independent watchers/parses of
// the same underlying data, no real benefit, just duplicated I/O).
//
// Not marked private — a future settings UI might want direct access
// to a key that neither Colors.qml nor Settings.qml expose by name.
Singleton {
    id: root

    // ── Metadata (top-level state.json fields, not part of style) ──
    property string wallpaper: ""
    property string mode: "dark"
    property string sourceType: "dynamic"
    property string sourceName: ""

    // ── Style, split into the SAME three scopes the daemon uses ────
    // shared:   colorN, background, foreground, radius, fontName —
    //           anything both the shell and Hyprland need.
    // shell:    Quickshell-only knobs (barHeight, widgetOpacity, ...).
    // hyprland: Hyprland-only knobs (gaps, blur, shadow, cursor, ...).
    //           The shell doesn't itself consume these — Hyprland
    //           reads them via the daemon's own template rendering,
    //           not through Quickshell — but they're exposed here too
    //           so a future settings UI can read/write them (e.g. a
    //           "Hyprland" tab) without this file changing.
    property var shared: ({})
    property var shell: ({})
    property var hyprland: ({})

    property FileView _cache: FileView {
        path: Quickshell.env("HOME") + "/.cache/nisfere/state.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const state = JSON.parse(text());
                root.wallpaper = state.wallpaper ?? "";
                root.mode = state.mode ?? "dark";
                root.sourceType = state.source_type ?? "dynamic";
                root.sourceName = state.source_name ?? "";

                const style = state.style ?? {};
                root.shared = style.shared ?? {};
                root.shell = style.shell ?? {};
                root.hyprland = style.hyprland ?? {};
            } catch (e) {
                console.warn("ThemeState: Parse error:", e);
            }
        }
        onLoadFailed: console.warn("ThemeState: state.json not found, using defaults")
    }
}
