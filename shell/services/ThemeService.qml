pragma Singleton
import QtQuick
import Quickshell
import qs.services

QtObject {
    id: root

    property string userHome: Quickshell.env("HOME")
    property string themesDir: "file://" + userHome + "/.config/nisfere/themes"

    // Η συνάρτηση που καλεί το backend μας
    function setColors(jsonPath, mode) {
        SocketService.sendCommand("theme", "set_colors", {
            colors_json_path: jsonPath,
            mode: mode || "dark" // Default σε dark αν δεν δοθεί
        });
    }
}
