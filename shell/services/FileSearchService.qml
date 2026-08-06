pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// File search via `find` — same Process + StdioCollector pattern.
// Plain QML Process rather than routed through the daemon: this is
// stateless, needs no privileges beyond the user's own session, and
// is already async on its own.
Singleton {
    id: root

    property var results: []   // [{ path, name }]
    property bool loading: false
    property string errorMessage: ""

    // `find` doesn't have a native --limit. We pipe it through `head`
    // in the shell to keep the optimization of not parsing thousands
    // of lines in QML.
    readonly property int maxResults: 100

    property Process _searchProc: Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim() !== "");
                root.results = lines.map(path => ({
                            path: path,
                            name: path.substring(path.lastIndexOf("/") + 1)
                        }));
                root.loading = false;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    root.errorMessage = text.trim();
                    root.loading = false;
                }
            }
        }
    }

    function search(query) {
        if (query.trim() === "") {
            root.results = [];
            root.errorMessage = "";
            root.loading = false;
            return;
        }
        
        // Explicit stop-before-restart guards against overlapping
        // invocations if you type faster than it can respond.
        if (root._searchProc.running)
            root._searchProc.running = false;
            
        root.errorMessage = "";
        root.loading = true;
        
        // Using sh -c allows us to use pipe (|) for `head` and discard 
        // permission denied errors (2>/dev/null). 
        // We pass the arguments securely as $1 and $2 to prevent injection.
        // Note: Searching ~/ is used because live searching / with find is too slow.
        root._searchProc.command = [
            "sh", 
            "-c", 
            "find ~/ -iname \"*$1*\" 2>/dev/null | head -n \"$2\"", 
            "find-search",             
            query,                     
            root.maxResults.toString() 
        ];
        
        root._searchProc.running = true;
    }

    function openFile(path) {
        Quickshell.execDetached(["xdg-open", path]);
    }

    function openContainingFolder(path) {
        const dir = path.substring(0, path.lastIndexOf("/")) || "/";
        Quickshell.execDetached(["xdg-open", dir]);
    }
}