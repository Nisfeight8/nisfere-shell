import QtQuick
import qs.core
import qs.services

// A single scoped provider's search() results (e.g. "@ssh ...") OR,
// when the provider is the default/unscoped "apps" one, the unified
// flat search across apps+ssh+git (SearchProviders.searchAll()) —
// both rendered via the shared ResultsListView.
Item {
    id: root

    readonly property var parsed: SearchProviders.parseQuery(ShellState.dashboardSearchText)
    readonly property var activeProvider: SearchProviders.findById(parsed.providerId)
    readonly property string providerQuery: parsed.rest

    // "apps" is the default/unscoped provider — that's exactly the
    // case that should show the unified merged list instead of just
    // apps' own results. Any other (explicitly "@"-scoped) provider
    // stays single-provider.
    readonly property bool isUnified: root.activeProvider && root.activeProvider.id === "apps"

    readonly property var results: {
        if (root.isUnified)
            return SearchProviders.searchAll(root.providerQuery);
        return (root.activeProvider && root.activeProvider.search) ? root.activeProvider.search(root.providerQuery) : [];
    }

    implicitWidth: listView.implicitWidth
    implicitHeight: listView.implicitHeight

    function navigate(delta) {
        listView.navigate(delta);
    }
    function activateSelected() {
        listView.activateSelected();
    }

    ResultsListView {
        id: listView
        anchors.fill: parent
        results: root.results
        maxListHeight: 360
        onResultActivated: (r, index) => {
            // In unified mode each row is tagged with its own
            // providerId (see SearchProviders.searchAll) since rows
            // can come from different providers; in scoped mode there
            // is no tag, so it just falls back to the one provider
            // this whole list is scoped to.
            const provider = SearchProviders.findById(r.providerId ?? root.activeProvider.id);
            if (!provider)
                return;
            if (r.panelId) {
                ShellState.openSearchDrilldown(r.panelId, provider.id);
            } else if (provider.pushOnActivate) {
                ShellState.openSearchDrilldown(provider.id, provider.id);
            } else {
                ShellState.closeDashboard();
            }
            if (r.action)
                r.action();
        }
    }
}
