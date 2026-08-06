import QtQuick
import qs.core
import qs.services

// Provider picker — rendered via the same ResultsListView/
// SearchResultRow every other results list in this shell uses
// (GenericResultsList, ColorsPanel), instead of its own hand-rolled
// 40px-row delegate. Same visual language everywhere a "pick one of
// these" list shows up.
//
// Still a search drilldown (see SearchComponent's drilldownComp /
// ShellState.dashboardSearchDrilldownPanelId "providerPicker" case) —
// not a Popup — since Popups reparent outside the drawer's own item
// tree, which sits outside ScreenBorder's input mask.
Item {
    id: root

    // "" (default) — used by the provider-button-triggered full panel,
    // shows every provider. Non-empty — used when SearchComponent
    // routes a partial "@t" match here: same component, same list,
    // just live-filtered.
    property string filterQuery: ""

    readonly property var allProviders: [
        {
            id: "apps",
            label: "Apps",
            icon: "layout-grid",
            keyword: ""
        }
    ].concat(SearchProviders.keywordProviders)

    readonly property var results: {
        const q = root.filterQuery.toLowerCase();
        const list = q === "" ? root.allProviders : root.allProviders.filter(p => p.label.toLowerCase().includes(q) || p.keyword.toLowerCase().includes(q));
        return list.map(p => ({
                    id: p.id,
                    title: p.label,
                    subtitle: p.keyword !== "" ? p.keyword : "",
                    icon: p.icon
                }));
    }

    implicitWidth: resultsList.implicitWidth
    implicitHeight: resultsList.implicitHeight

    function navigate(delta) {
        resultsList.navigate(delta);
    }
    function activateSelected() {
        resultsList.activateSelected();
    }

    ResultsListView {
        id: resultsList
        anchors.fill: parent
        results: root.results
        emptyText: "No matching providers"
        maxListHeight: 6 * rowHeight // cap at ~6 visible rows
        onResultActivated: (r, index) => {
            const p = SearchProviders.findById(r.id);
            if (!p)
                return;
            // Setting dashboardSearchText (rather than reaching into
            // DashboardSearchBar's own `text` directly, which this
            // file has no handle on) is enough — DashboardSearchBar
            // already syncs FROM ShellState via its existing
            // onDashboardSearchTextChanged Connections handler.
            ShellState.dashboardSearchText = p.keyword !== "" ? p.keyword + " " : "";
            ShellState.dashboardSearchProviderId = p.id;
            ShellState.closeSearchDrilldown();
        }
    }
}
