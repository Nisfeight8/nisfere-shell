pragma Singleton

import QtQuick
import Quickshell
import qs.services

QtObject {
    id: root

    property string userHome: Quickshell.env("HOME")
    property string wallpaperDir: "file://" + userHome + "/Pictures/Wallpapers"

    function setWallpaper(path, apply_colors) {
        SocketService.sendCommand("theme", "set_wallpaper", {
            wallpaper_path: path,
            apply_colors: apply_colors,
            mode: "dark"
        });
    }
    function previewWallpaper(path) {
        SocketService.sendCommand("theme", "preview_wallpaper", {
            wallpaper_path: path
        });
    }
}
