import QtQuick
import qs.core

// Generic "list of SearchResultRow" shell — knows NOTHING about
// SearchProviders/ShellState/ThemeActions/DesktopEntries. Takes a
// plain `results` array (each item shaped for SearchResultRow: id,
// title, subtitle?, icon?, thumbnail?, actions?, swatches?,
// confirmed?) and handles: rendering, stable sizing, empty/loading
// text, and keyboard navigation (navigate/activateSelected, same
// convention every panel in this shell already uses).
//
// Extracted because GenericResultsList, ColorsPanel, and
// AppLauncherPanel's search mode had each independently rebuilt this
// exact same ListView + sizing-math + empty-state + navigate/
// activateSelected combo, each guessing its own row-height/max-height
// constants — one had already silently drifted (ColorsPanel guessed
// rowHeight: 44 in a comment, but never actually used it in its size
// formula, and SearchResultRow's real fixed height is 56).
Item {
    id: root

    required property var results

    property string emptyText: "No results"
    property string loadingText: "" // shown instead of emptyText while loading is true
    property bool loading: false

    // Callers should NOT rely on a fixed value from outside; this
    // mirrors SearchResultRow's own hardcoded `height: 56` — kept as
    // one named constant so the two can't silently drift apart the
    // way ColorsPanel's guessed 44 did. Update both together if
    // SearchResultRow's height ever changes.
    readonly property int rowHeight: 56
    readonly property int rowSpacing: 4
    property int emptyStateHeight: 90
    property int maxListHeight: 400

    signal resultActivated(var result, int index)

    property int selectedIndex: 0

    // Prefers the ListView's own real measured contentHeight (exact);
    // falls back to the rowHeight*count formula only for the very
    // first frame before layout has run once (contentHeight starts at
    // 0 then) — same bootstrap trick AppLauncherPanel's search mode
    // already used, now shared instead of reimplemented per-caller.
    readonly property int listContentHeight: results.length === 0 ? emptyStateHeight : Math.min(list.contentHeight || (results.length * rowHeight + Math.max(0, results.length - 1) * rowSpacing), maxListHeight)

    implicitWidth: 640
    implicitHeight: listContentHeight

    function navigate(delta) {
        if (root.results.length === 0)
            return;
        selectedIndex = Math.max(0, Math.min(root.results.length - 1, selectedIndex + delta));
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }
    function activateSelected() {
        const r = root.results[selectedIndex];
        if (r)
            root.resultActivated(r, selectedIndex);
    }

    onResultsChanged: selectedIndex = 0

    Text {
        anchors.centerIn: parent
        visible: root.results.length === 0
        text: root.loading && root.loadingText !== "" ? root.loadingText : root.emptyText
        color: Theme.foreground
        opacity: 0.4
        font.family: Theme.fontName
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
    }

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        visible: root.results.length > 0
        spacing: root.rowSpacing
        model: root.results

        delegate: SearchResultRow {
            required property var modelData
            required property int index
            result: modelData
            isSelected: index === root.selectedIndex
            onActivated: {
                root.selectedIndex = index;
                root.activateSelected();
            }
        }
    }
}
