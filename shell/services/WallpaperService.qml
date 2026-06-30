pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import qs.services

QtObject {
    id: root

    // Dynamic path resolution using Quickshell.env
    property string userHome: Quickshell.env("HOME")
    property string wallpaperDir: "file://" + userHome + "/Pictures/Wallpapers"

    property FolderListModel model: FolderListModel {
        folder: root.wallpaperDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png"]
        showDirs: false
        sortField: FolderListModel.Name
    }

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
