pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Cached hyprctl state (clients / workspaces / monitors), refreshed on
// Hyprland IPC events instead of polling. Consumed by Overview.qml /
// OverviewWindow.qml for window positions, sizes, and workspace ids —
// data that Quickshell.Hyprland's own models don't expose directly
// (e.g. `at`, `size`, `workspace.id` per client).
Singleton {
    id: root

    property var windowList: []
    property var windowByAddress: ({})
    property var addresses: []

    property var allWorkspaces: []
    property var workspaceIds: []
    property var monitors: []

    // Debounce so a burst of events (e.g. dragging a window) doesn't
    // spawn a `hyprctl` process per event.
    property int debounceMs: 60
    property bool pendingWindows: false
    property bool pendingWorkspaces: false
    property bool pendingMonitors: false

    function scheduleUpdate(windows, workspaces, monitors) {
        pendingWindows = pendingWindows || !!windows;
        pendingWorkspaces = pendingWorkspaces || !!workspaces;
        pendingMonitors = pendingMonitors || !!monitors;
        debounceTimer.restart();
    }

    function flush() {
        if (pendingWindows) {
            pendingWindows = false;
            getClients.running = true;
        }
        if (pendingWorkspaces) {
            pendingWorkspaces = false;
            getWorkspaces.running = true;
        }
        if (pendingMonitors) {
            pendingMonitors = false;
            getMonitors.running = true;
        }
    }

    Component.onCompleted: scheduleUpdate(true, true, true)

    Timer {
        id: debounceTimer
        interval: root.debounceMs
        repeat: false
        onTriggered: root.flush()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const name = `${event?.name ?? ""}`;
            if (["openwindow", "closewindow", "movewindow", "movewindowv2", "windowtitle", "fullscreen"].includes(name)) {
                root.scheduleUpdate(true, true, false);
            } else if (name.startsWith("workspace") || name === "focusedmon" || name === "focusedmonv2") {
                root.scheduleUpdate(false, true, false);
            } else if (name.startsWith("monitor") || name === "configreloaded") {
                root.scheduleUpdate(true, true, true);
            }
        }
    }

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

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.allWorkspaces = JSON.parse(text);
                    root.workspaceIds = root.allWorkspaces.filter(ws => ws.id >= 1 && ws.id <= 100).map(ws => ws.id);
                } catch (e) {
                    console.warn("HyprlandData: failed to parse workspaces:", e);
                }
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text);
                } catch (e) {
                    console.warn("HyprlandData: failed to parse monitors:", e);
                }
            }
        }
    }
}
