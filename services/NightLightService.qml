pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property Process _hyprctlProc: Process {
    }
    property FileView _stateFile: FileView {
        blockLoading: true
        path: Quickshell.env("HOME") + "/.cache/nisfere/nightlight_state"
        watchChanges: true

        onLoaded: {
            root.isActive = (text().trim() === "1");
        }
        onTextChanged: {
            root.isActive = (text().trim() === "1");
        }
    }
    property bool isActive: false

    function toggle() {
        const newState = !root.isActive;
        const shaderPath = Quickshell.env("HOME") + "/.config/hypr/nightlight.glsl";

        if (newState) {
            _hyprctlProc.exec(["hyprctl", "keyword", "decoration:screen_shader", shaderPath]);
            _stateFile.setText("1");
        } else {
            _hyprctlProc.exec(["hyprctl", "keyword", "decoration:screen_shader", "[[EMPTY]]"]);
            _stateFile.setText("0");
        }
    }
}
