import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services
import "../search"

// AppLauncher adapted for CentralLauncher — SideMenu on the left
// (All Applications / Favorites / Most Used / Recently + categories),
// ResultsListView/SearchResultRow on the right showing whichever
// tab/category is currently selected.
//
// This file used to also have its own search mode (a `searchText`
// prop + isSearching/searchResults/displayResults), but nothing ever
// fed it non-empty text in either place this component is used
// (SearchComponent's "apps" entry only renders this when the query is
// EMPTY; DashboardContent's standalone "appLauncherFull" never had a
// search field at all) — so that whole branch was unreachable dead
// code. Removed rather than adding a text field just to make it
// reachable: a search box here would duplicate the Dashboard's own
// top-level search, which already merges apps in
// (GenericResultsList's isUnified + SearchProviders.searchAll()).
// Browsing by SideMenu tab/category is a complete, separate
// interaction model on its own — it doesn't need a "search within
// this category" feature layered on top to be useful.
Item {
    id: root
    property real uiScale: 1.0
    implicitWidth: 640 * uiScale
    implicitHeight: 400 * uiScale

    function _findApp(name) {
        const apps = DesktopEntries.applications.values;
        for (let i = 0; i < apps.length; i++)
            if (apps[i].name === name)
                return apps[i];
        return null;
    }

    readonly property var mainCategories: ["AudioVideo", "Audio", "Video", "Development", "Education", "Game", "Graphics", "Network", "Office", "Science", "Settings", "System", "Utility",]
    readonly property var categoryIcons: ({
            "AudioVideo": "music",
            "Audio": "music",
            "Video": "video",
            "Development": "code",
            "Education": "graduation-cap",
            "Game": "gamepad-2",
            "Graphics": "image",
            "Network": "network",
            "Office": "file-text",
            "Science": "flask-conical",
            "Settings": "settings",
            "System": "cpu",
            "Utility": "wrench"
        })

    readonly property var allAppsArray: DesktopEntries.applications.values.slice().sort((a, b) => a.name.localeCompare(b.name))

    readonly property var favoriteApps: AppUsageService.favorites.map(n => root._findApp(n)).filter(a => a !== null)
    readonly property var recentApps: AppUsageService.recentNames.map(n => root._findApp(n)).filter(a => a !== null)
    readonly property var mostUsedApps: AppUsageService.mostUsedNames.map(n => root._findApp(n)).filter(a => a !== null)

    readonly property var presentCategories: {
        const set = new Set();
        for (const app of root.allAppsArray)
            for (const cat of (app.categories || []))
                if (root.mainCategories.indexOf(cat) !== -1)
                    set.add(cat);
        return root.mainCategories.filter(c => set.has(c));
    }

    readonly property var sideMenuModel: {
        const base = [
            {
                icon: "layout-grid",
                title: "All Applications",
                key: "all"
            },
            {
                icon: "star",
                title: "Favorites",
                key: "favorites"
            },
            {
                icon: "trending-up",
                title: "Most Used",
                key: "mostUsed"
            },
            {
                icon: "clock",
                title: "Recently",
                key: "recent"
            },
        ];
        const catItems = root.presentCategories.map(c => ({
                    icon: root.categoryIcons[c] || "shapes",
                    title: c,
                    key: "category:" + c
                }));
        return base.concat(catItems);
    }

    readonly property var currentTabApps: {
        const tab = ShellState.dashboardSearchAppsSubTab;
        if (tab.startsWith("category:")) {
            const cat = tab.substring("category:".length);
            return root.allAppsArray.filter(a => (a.categories || []).indexOf(cat) !== -1);
        }
        switch (tab) {
        case "favorites":
            return root.favoriteApps;
        case "mostUsed":
            return root.mostUsedApps;
        case "recent":
            return root.recentApps;
        default:
            return root.allAppsArray;
        }
    }

    // The current SideMenu tab's apps, mapped to the same
    // SearchResultRow shape via DesktopEntryService.toResultRow that
    // SearchProviders' own "apps" provider search() uses for the
    // unified top-level search — same canonical row mapping, one
    // less place for it to drift.
    readonly property var results: root.currentTabApps.map(a => DesktopEntryService.toResultRow(a))

    // launchSelected() (rather than just relying on
    // resultsList.activateSelected() directly) exists because callers
    // (SearchComponent's inline "apps" mapping, DashboardContent's
    // "appLauncherFull" case) each override this component instance's
    // own activateSelected() to conditionally closeDashboard() based
    // on whether a launch actually happened.
    function launchSelected() {
        const r = resultsList.results[resultsList.selectedIndex];
        if (r && r.action) {
            r.action();
            return true;
        }
        return false;
    }
    function navigate(delta) {
        resultsList.navigate(delta);
    }
    function activateSelected() {
        resultsList.activateSelected();
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        SideMenu {
            Layout.fillHeight: true
            menuModel: root.sideMenuModel
            currentIndex: root.sideMenuModel.findIndex(m => m.key === ShellState.dashboardSearchAppsSubTab)
            onTabClicked: idx => {
                ShellState.dashboardSearchAppsSubTab = root.sideMenuModel[idx].key;
            }
        }

        // ── List area ────────────────────────────────────────────
        ResultsListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true

            results: root.results
            emptyText: "Nothing here yet"
            maxListHeight: 400

            onResultActivated: (r, index) => {
                if (r.action)
                    r.action();
                ShellState.closeDashboard();
            }
        }
    }
}
