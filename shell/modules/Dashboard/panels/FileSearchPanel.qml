import QtQuick
import qs.core
import qs.services
import "../search"

Item {
    id: root
    property real uiScale: 1.0

    property string searchText: ""

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

    // Width fixed, scaled by uiScale (same as AppLauncherPanel/
    // ClipboardPanel/ColorsPanel). Height genuinely bottom-up from
    // resultsList's own implicit height.
    implicitWidth: 640 * uiScale
    implicitHeight: resultsList.implicitHeight

    ResultsListView {
        id: resultsList
        uiScale: root.uiScale
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
        maxListHeight: 400 * root.uiScale
        onResultActivated: (r, index) => {
            if (r.action)
                r.action();
            ShellState.closeDashboard();
        }
    }
}
