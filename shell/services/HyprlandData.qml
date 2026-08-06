pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // ── 1. NATIVE API (Γρήγορο, χωρίς καθυστερήσεις, έχει τα πάντα εκτός από x,y,w,h)
    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property var monitors: Hyprland.monitors
    readonly property bool usingLua: Hyprland.usingLua
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    // Φτιάχνουμε το workspaceIds απευθείας από το native API (δεν χρειάζεται process!)
    readonly property var workspaceIds: {
        let ids = [];
        for (let i = 0; i < workspaces.values.length; i++) {
            let id = workspaces.values[i].id;
            if (id >= 1 && id <= 100) ids.push(id);
        }
        return ids.sort((a, b) => a - b);
    }

    // ── 2. JSON ΔΕΔΟΜΕΝΑ (Μόνο για τα παραθυρα, για να έχουμε τα "at" και "size" στο Overview)
    property var windowList: []
    property var windowByAddress: ({})
    property var addresses: []

    property int debounceMs: 60
    property bool pendingWindows: false
    property int bootRetryCount: 0

    // Καλούμε αυτή τη συνάρτηση μόνο όταν κάτι αλλάζει στα παράθυρα
    function scheduleClientsUpdate() {
        pendingWindows = true;
        debounceTimer.restart();
    }

    Timer {
        id: debounceTimer
        interval: root.debounceMs
        repeat: false
        onTriggered: {
            if (pendingWindows) {
                pendingWindows = false;
                // Απενεργοποίηση και ενεργοποίηση για να τρέξει σίγουρα
                getClients.running = false;
                getClients.running = true;
            }
        }
    }

    // ── 3. ΕΚΚΙΝΗΣΗ / ΣΥΓΧΡΟΝΙΣΜΟΣ ΜΕ ΤΟ LUA SCRIPT ────────────────────
    Timer {
        id: bootSyncTimer
        interval: 400
        repeat: true
        running: true
        onTriggered: {
            bootRetryCount++;
            
            // Αναγκάζουμε το native API να δει τις αλλαγές του Lua
            Hyprland.refreshToplevels();
            Hyprland.refreshWorkspaces();
            Hyprland.refreshMonitors();

            // Αναγκάζουμε και το JSON να κατεβάσει τις θέσεις των παραθύρων
            root.scheduleClientsUpdate();

            // Σταματάει μετά από ~2.5 δευτερόλεπτα (όταν το Lua έχει τελειώσει σίγουρα)
            if (bootRetryCount >= 6) {
                running = false;
            }
        }
    }

    // ── 4. ΕΠΕΞΕΡΓΑΣΙΑ ΣΥΜΒΑΝΤΩΝ (IPC EVENTS) ───────────────────────────
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = `${event?.name ?? ""}`;
            if (n.endsWith("v2")) return;

            if (["workspace", "moveworkspace", "focusedmon", "activespecial"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
                // Εδώ τα παράθυρα κουνήθηκαν, οπότε τρέχουμε το Process για νέα x,y,w,h
                root.scheduleClientsUpdate();
            } else if (n.includes("mon")) {
                Hyprland.refreshMonitors();
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
            } else if (n.includes("window") || n.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(n)) {
                Hyprland.refreshToplevels();
                // Εδώ τα παράθυρα άλλαξαν κατάσταση/μέγεθος, οπότε τρέχουμε το Process
                root.scheduleClientsUpdate();
            }
        }
    }

    // ── 5. ΤΟ ΜΟΝΑΔΙΚΟ PROCESS ΠΟΥ ΑΠΕΜΕΙΝΕ ─────────────────────────────
    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.windowList = JSON.parse(text);
                    const byAddr = {};
                    for (const w of root.windowList)
                        byAddr[w.address] = w;
                    root.windowByAddress = byAddr;
                    root.addresses = root.windowList.map(w => w.address);
                } catch (e) { 
                    console.warn("HyprlandData: failed to parse clients:", e);
                }
            }
        }
    }

    // ── 6. HELPER FUNCTIONS ΓΙΑ ΤΟ WALLPAPER ΚΑΙ ΤΟ ACTIVE WINDOW ───────
    function activeWindowForScreen(screenName) {
        const monitor = root.monitors.values.find(m => m.name === screenName);
        if (!monitor || !monitor.activeWorkspace)
            return null;
        
        const tops = monitor.activeWorkspace.toplevels.values;
        return tops.length > 0 ? tops[0] : null;
    }

    function hasFullscreenOnScreen(screenName) {
        const monitor = root.monitors.values.find(m => m.name === screenName);
        return monitor && monitor.activeWorkspace ? monitor.activeWorkspace.hasFullscreen : false;
    }

    function isShowingWallpaper(screenName) {
        return root.activeWindowForScreen(screenName) === null;
    }

    readonly property bool anyScreenShowingWallpaper: {
        let showing = false;
        for (let i = 0; i < root.monitors.values.length; i++) {
            if (root.isShowingWallpaper(root.monitors.values[i].name)) {
                showing = true;
                break;
            }
        }
        return showing;
    }
}