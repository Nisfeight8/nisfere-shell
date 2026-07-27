pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property Process _hyprctlProc: Process {}
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

        if (newState) {
            _stateFile.setText("1");
            // Το -T είναι η μέρα και το -t η νύχτα. Βάζοντας 4000 και στα δύο,
            // το wlsunset εφαρμόζει το φίλτρο ακαριαία, ό,τι ώρα και να είναι!
            Quickshell.execDetached(["wlsunset", "-T", "10000", "-t", "4000"]);
        } else {
            _stateFile.setText("0");
            // Το pkill κλείνει το wlsunset και η οθόνη επανέρχεται στο κανονικό
            Quickshell.execDetached(["pkill", "wlsunset"]);
        }
    }
}
