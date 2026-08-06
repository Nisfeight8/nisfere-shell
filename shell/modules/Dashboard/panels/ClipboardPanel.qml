import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "../search"
// Clipboard history — same "own header, ResultsListView for the list"
// structure as ColorsPanel/WallpapersPanel. Search/filter/clear-all/
// refresh logic all live HERE, not inside SearchProviders — keeping
// per-panel UI concerns out of the providers file (same reasoning
// already established for ColorsPanel/WallpapersPanel).
//
// Converted from a standalone FocusScope (with its own
// forceActiveFocus()/Keys.onReturnPressed) to a plain Item — same
// convention as every other provider panel here: DashboardSearchBar
// already forwards navigate()/activateSelected() generically, so this
// doesn't need to own keyboard focus itself anymore.
Item {
    id: root

    property string searchText: ""

    readonly property var filteredEntries: root.searchText === "" ? ClipboardService.entries : ClipboardService.entries.filter(e => e.preview.toLowerCase().includes(root.searchText.toLowerCase()))

    readonly property var results: root.filteredEntries.map(e => ({
                id: "clip-" + e.id,
                title: e.preview,
                icon: "clipboard",
                actions: [
                    {
                        icon: "x",
                        trigger: () => ClipboardService.deleteEntry(e.raw)
                    }
                ],
                raw: e.raw
            }))

    function navigate(delta) {
        resultsList.navigate(delta);
    }
    function activateSelected() {
        resultsList.activateSelected();
    }

    Component.onCompleted: ClipboardService.refresh()

    // Bottom-up from header + divider + resultsList's own implicit
    // height — resultsList (ResultsListView) already handles its own
    // stable sizing internally.
    implicitWidth: 420
    implicitHeight: headerRow.implicitHeight + dividerRect.height + resultsList.implicitHeight + (mainColumn.spacing * 2) + (mainColumn.anchors.margins * 2)

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // ── Header ────────────────────────────────────────────────
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 6

            LucideIcon {
                icon: "clipboard-list"
                size: 14
                color: Theme.selected
            }

            Text {
                Layout.fillWidth: true
                leftPadding: 4
                text: ClipboardService.loading ? "Loading..." : ClipboardService.entries.length + " item" + (ClipboardService.entries.length !== 1 ? "s" : "")
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13
                font.bold: true
            }

            IconButton {
                icon: "refresh-cw"
                size: 28
                iconSize: 13
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                tooltipText: "Refresh"
                spinning: ClipboardService.loading
                onTapped: ClipboardService.refresh()
            }

            IconButton {
                icon: "trash-2"
                size: 28
                iconSize: 13
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                visible: ClipboardService.entries.length > 0
                hoverColor: Theme.color1
                activeColor: Theme.color1
                tooltipText: "Clear all"
                onTapped: ClipboardService.wipeAll()
            }
        }

        Rectangle {
            id: dividerRect
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.4
        }

        // ── List ──────────────────────────────────────────────────
        ResultsListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            results: root.results
            loading: ClipboardService.loading
            loadingText: "Loading..."
            emptyText: root.searchText !== "" ? "No matching clipboard entries" : "No clipboard history"
            maxListHeight: 400
            onResultActivated: (r, index) => {
                ClipboardService.copyEntry(r.raw);
                ShellState.closeDashboard();
            }
        }
    }
}
