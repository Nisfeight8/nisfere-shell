pragma Singleton
import QtQuick
import Quickshell
import qs.services

QtObject {
    id: root

    // ── Properties ───────────────────────────────────────────────
    // Kept for FolderListModel in components that scan locally
    readonly property string wallpaperDir: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers"

    // Populated by daemon responses
    property var wallpapers: []
    property var themes: []
    property var currentState: null   // ThemeState dict: wallpaper, mode, source_type, source_name, colors

    // ── Signals ──────────────────────────────────────────────────
    signal wallpaperSet(bool success, string path)
    signal themeSet(bool success, string name)
    signal stateLoaded(var state)
    signal wallpapersLoaded(var list)
    signal themesLoaded(var list)

    // ── Wire up on load ──────────────────────────────────────────
    Component.onCompleted: {
        SocketService.messageReceived.connect(_handleMessage);
        SocketService.connected.connect(fetchState);     // sync state on every (re)connect
    }

    // ── Incoming message router ───────────────────────────────────
    function _handleMessage(type, payload) {
        switch (type) {
        case "theme_applied":
            // set_wallpaper response has "wallpaper"; set_colors has "theme"
            if (payload.wallpaper !== undefined)
                root.wallpaperSet(payload.success ?? false, payload.wallpaper);
            else
                root.themeSet(payload.success ?? false, payload.theme ?? "");
            // Re-fetch state so currentState stays fresh
            if (payload.success)
                fetchState();
            break;
        case "theme_state":
            root.currentState = payload;
            root.stateLoaded(payload);
            break;
        case "wallpapers_list":
            root.wallpapers = payload.wallpapers ?? [];
            root.wallpapersLoaded(root.wallpapers);
            break;
        case "themes_list":
            root.themes = payload.themes ?? [];
            root.themesLoaded(root.themes);
            break;
        case "error":
            console.warn("WallpaperService: daemon error for action '" + (payload.action ?? "?") + "':", payload.error);
            break;
        }
    }

    // ── Wallpaper actions ────────────────────────────────────────
    function setWallpaper(path, applyColors, mode) {
        SocketService.sendCommand("theme", "set_wallpaper", {
            wallpaper_path: path,
            apply_colors: applyColors,
            mode: mode ?? "dark"
        });
    }

    function previewWallpaper(path) {
        SocketService.sendCommand("theme", "preview_wallpaper", {
            wallpaper_path: path
        });
    }

    // ── Color theme actions ──────────────────────────────────────
    function setColors(themeName, mode) {
        SocketService.sendCommand("theme", "set_colors", {
            theme_name: themeName,
            mode: mode ?? "dark"
        });
    }

    // ── Fetch methods ────────────────────────────────────────────
    function fetchState() {
        SocketService.sendCommand("theme", "get_state", {});
    }

    function fetchWallpapers() {
        SocketService.sendCommand("theme", "get_wallpapers", {});
    }

    function fetchThemes() {
        SocketService.sendCommand("theme", "get_themes", {});
    }
}
