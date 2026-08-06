pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "search"
import "panels"
import "panels/AppLauncherPanel"

// The Dashboard's Search page — visible whenever
// ShellState.dashboardActiveComponent === "search". Self-contained:
// owns the search bar + the results/drilldown loader for every
// genuine SEARCH PROVIDER (apps/wallpapers/colors/clipboard/ssh/git/
// commands) and the "@" provider-picker.
//
// The standalone top-level tools (appLauncherFull/docker/sysmon/
// settings) no longer live inside this file at all — they're peers of
// "search" itself now (see ShellState.dashboardActiveComponent),
// rendered directly by DashboardContent with no search-bar chrome.
// This file genuinely only ever deals with things that make sense to
// filter/search by typed text.
Item {
    id: root
    focus: true

    implicitWidth: mainColumn.implicitWidth
    implicitHeight: mainColumn.implicitHeight

    readonly property var parsed: SearchProviders.parseQuery(ShellState.dashboardSearchText)
    readonly property string providerQuery: parsed.rest
    readonly property bool hasDrilldown: ShellState.dashboardSearchHasDrilldown

    // Most providers just update which one search is scoped to. But
    // docker/sysmon/settings are "standalone" (see SearchProviders) —
    // they don't render inline inside search at all anymore, they're
    // peers of "search" itself (ShellState.dashboardActiveComponent).
    // The moment typing (or the "@" picker) fully matches one of their
    // keywords, redirect straight to the real top-level component
    // instead of falling through to an empty GenericResultsList (which
    // is what happened before this fix — these providers have no
    // `search()` function to call, so it just showed "No results").
    // Most providers just update which one search is scoped to. Two
    // exceptions redirect away from rendering anything here at all:
    //   "standalone" — a real top-level component to show instead
    //                  (docker/sysmon/settings) — see ShellState.
    //   "immediate"  — no component at all, just run the provider's
    //                  own action() and close (e.g. colorpicker) —
    //                  was previously a search() result you still had
    //                  to click/Enter on for nothing to actually pick.
    onParsedChanged: {
        const p = SearchProviders.findById(parsed.providerId);
        if (p && p.standalone) {
            ShellState.openDashboardComponent(ShellState.activeScreenName, p.id);
            return;
        }
        if (p && p.immediate) {
            ShellState.closeDashboard();
            p.action();
            return;
        }
        ShellState.dashboardSearchProviderId = parsed.providerId;
    }

    // Local map from providerId -> this file's own Component ids.
    // Previously this lived as a mutated `.component` field written
    // onto SearchProviders' provider objects in Component.onCompleted
    // — but SearchProviders' providers array is a plain `var` array
    // (no change signal), so that first mutation could lose a race
    // against sourceComp's first evaluation, patched over with a
    // providersReady flag. Keeping the mapping local instead removes
    // the race entirely: these are sibling ids in THIS file, valid
    // from object-tree construction, before any binding ever runs —
    // no "not ready yet" state can exist.
    readonly property var _componentMap: ({
        "apps": appsComponent,
        "wallpapers": wallpapersComponent,
        "colors": colorsComponent,
        "clipboard": clipboardComponent,
        "files": filesComponent,
        "providerSuggest": providerSuggestComponent
    })

    function _resultsComponentFor(providerId) {
        // "apps" with actual text typed goes to the unified merged
        // list (GenericResultsList, via its own isUnified check) — not
        // the rich browse-mode AppLauncherPanel, which is reserved for
        // the empty-query "just opened search" landing state. Every
        // other providerId (including "apps" with an empty query)
        // keeps using the plain map lookup.
        if (providerId === "apps" && root.providerQuery !== "")
            return searchResultsComp;
        return root._componentMap[providerId] ?? searchResultsComp;
    }

    // A single optional drilldown within search results — today only
    // "providerPicker" (the button next to the search field), rendered
    // directly since there's no PanelStackHost switch to route through
    // anymore. Add another `if` here once a real git/ssh drilldown view
    // exists — no dispatcher component needed for just two or three
    // cases.
    function _drilldownComponentFor(panelId) {
        if (panelId === "providerPicker")
            return drilldownProviderPickerComponent;
        return null;
    }

    Component {
        id: appsComponent
        AppLauncherPanel {
            id: appsPanelInline
            function activateSelected() {
                if (appsPanelInline.launchSelected())
                    ShellState.closeDashboard();
            }
        }
    }
    Component {
        id: wallpapersComponent
        WallpapersPanel {
            searchText: root.providerQuery
        }
    }
    Component {
        id: colorsComponent
        ColorsPanel {
            searchText: root.providerQuery
        }
    }
    Component {
        id: clipboardComponent
        ClipboardPanel {
            searchText: root.providerQuery
        }
    }
    Component {
        id: filesComponent
        FileSearchPanel {
            searchText: root.providerQuery
        }
    }
    Component {
        id: searchResultsComp
        GenericResultsList {}
    }
    Component {
        id: providerSuggestComponent
        ProviderPicker {
            filterQuery: root.providerQuery
        }
    }
    Component {
        id: drilldownProviderPickerComponent
        ProviderPicker {}
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 15

        DashboardSearchBar {
            id: dashboardSearchBar
            Layout.fillWidth: true

            // Escape now always closes the WHOLE Dashboard — no more
            // graduated pop-panel/clear-text/exit-search-only steps.
            onEscapePressed: ShellState.closeDashboard()

            onKeyPressed: e => {
                if (e.key !== Qt.Key_Up && e.key !== Qt.Key_Down && e.key !== Qt.Key_Left && e.key !== Qt.Key_Right)
                    return;
                if (searchLoader.item && searchLoader.item.navigate) {
                    const delta = (e.key === Qt.Key_Up || e.key === Qt.Key_Left) ? -1 : 1;
                    searchLoader.item.navigate(delta);
                }
            }
            onAccepted: {
                if (searchLoader.item && searchLoader.item.activateSelected)
                    searchLoader.item.activateSelected();
            }
        }

        AnimLoader {
            id: searchLoader
            Layout.fillWidth: true
            sourceComp: root.hasDrilldown ? root._drilldownComponentFor(ShellState.dashboardSearchDrilldownPanelId) : root._resultsComponentFor(ShellState.dashboardSearchProviderId)
        }
    }

    Keys.onEscapePressed: ShellState.closeDashboard()
}
