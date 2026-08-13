pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Discovers git repos under $HOME by finding ".git" directories — same
// general Process + StdioCollector pattern as FileSearchService.
// ".git" is a rare, specific directory name (unlike a broad file-search
// substring), so a plain unbounded `find` here is fast enough in
// practice without needing the timeout/head-capping machinery that
// broad file search needed.
Singleton {
    id: root

    property var repos: []  // [{ path, name }]

    property Process _searchProc: Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim() !== "");
                // Each line is a ".git" directory itself — the actual
                // repo root is its parent.
                root.repos = lines.map(gitDir => {
                        const repoPath = gitDir.replace(/\/\.git$/, "");
                        const parts = repoPath.split("/").filter(p => p !== "");
                        return {
                            path: repoPath,
                            name: parts.length > 0 ? parts[parts.length - 1] : repoPath
                        };
                    });
            }
        }
    }

    function refresh() {
        if (root._searchProc.running)
            root._searchProc.running = false;
        // Same prune list as file search — skips the usual noisy/heavy
        // directories nobody keeps real repos inside of.
        root._searchProc.command = [
            "sh",
            "-c",
            "find ~/ -maxdepth 6 \\( -path '*/.cache' -o -path '*/node_modules' -o -path '*/.local/share/Trash' \\) -prune -o -type d -name '.git' -print 2>/dev/null"
        ];
        root._searchProc.running = true;
    }

    Component.onCompleted: refresh()
}
