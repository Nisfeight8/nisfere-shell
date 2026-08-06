import QtQuick
import qs.core
import qs.services
import "../search"

Item {
    id: root

    property string searchText: ""

    // Debounced — don't fire a `locate` process on every single
    // keystroke, same reasoning as WallpapersPanel's previewTimer.
    Timer {
        id: debounceTimer
        interval: 150
        onTriggered: FileSearchService.search(root.searchText)
    }
    onSearchTextChanged: debounceTimer.restart()

    readonly property var results: FileSearchService.results.map(r => ({
                id: r.path,
                title: r.name,
                subtitle: r.path,
                icon: "file",
                actions: [
                    {
                        icon: "folder-open",
                        trigger: () => {
                            FileSearchService.openContainingFolder(r.path);
                            ShellState.closeDashboard();
                        }
                    }
                ],
                action: () => FileSearchService.openFile(r.path)
            }))

    function navigate(delta) {
        resultsList.navigate(delta);
    }
    function activateSelected() {
        resultsList.activateSelected();
    }

    implicitWidth: 640
    implicitHeight: resultsList.implicitHeight

    ResultsListView {
        id: resultsList
        anchors.fill: parent
        results: root.results
        loading: FileSearchService.loading
        loadingText: "Searching..."
        emptyText: {
            if (FileSearchService.errorMessage !== "")
                return FileSearchService.errorMessage;
            if (root.searchText.trim() === "")
                return "Type to search files";
            return "No matching files";
        }
        maxListHeight: 400
        onResultActivated: (r, index) => {
            if (r.action)
                r.action();
            ShellState.closeDashboard();
        }
    }
}
