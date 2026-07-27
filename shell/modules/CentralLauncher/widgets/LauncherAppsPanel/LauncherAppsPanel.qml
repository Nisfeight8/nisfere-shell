import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.core
import qs.services

// AppLauncher adapted for CentralLauncher — SideMenu on the left
// (All Applications / Favorites / Most Used / Recently), one unified
// GridView on the right. Search overrides the sub-tab entirely (always
// searches ALL applications, regardless of which sub-tab you're on).
//
// Uses GridView (not Flow+Repeater) specifically for virtualization —
// with 150-300+ installed apps, Flow+Repeater decoded every single
// icon immediately regardless of scroll position, a real avoidable RAM
// cost. GridView only instantiates visible rows + a small cache buffer.
Item {
    id: root

    property int columns: 4
    property string searchText: ""
    property string selectedAppName: ""

    readonly property bool isSearching: searchText !== ""

    function _findApp(name) {
        const apps = DesktopEntries.applications.values;
        for (let i = 0; i < apps.length; i++)
            if (apps[i].name === name)
                return apps[i];
        return null;
    }

    // freedesktop.org Desktop Entry Spec "Main Categories" — filtering
    // to just these avoids noisy vendor-specific tags (GTK, Qt,
    // X-GNOME-Utilities, etc.) that many .desktop files also include.
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

    // Only main categories that actually have at least one installed
    // app, kept in mainCategories' canonical order.
    readonly property var presentCategories: {
        const set = new Set();
        for (const app of root.allAppsArray)
            for (const cat of (app.categories || []))
                if (root.mainCategories.indexOf(cat) !== -1)
                    set.add(cat);
        return root.mainCategories.filter(c => set.has(c));
    }

    // Flat SideMenu model: base tabs + one tab per present category.
    // Category tabs are keyed "category:<Name>" in launcherAppsSubTab.
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

    // Whichever list the current sub-tab shows (ignored while searching).
    readonly property var currentTabApps: {
        const tab = ShellState.launcherAppsSubTab;
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

    // The SINGLE source of truth for what the grid renders — always a
    // plain array, pre-filtered.
    readonly property var displayApps: root.isSearching ? root.allAppsArray.filter(a => a.name.toLowerCase().includes(root.searchText.toLowerCase())) : root.currentTabApps

    function _launch(appData) {
        appData.execute();
        AppUsageService.recordLaunch(appData.name);
        ShellState.appLauncherOpened = false;
    }

    function launchSelected() {
        const app = root._findApp(selectedAppName);
        if (app) {
            root._launch(app);
            return true;
        }
        return false;
    }

    function navigate(delta) {
        const names = root.displayApps.map(a => a.name);
        if (!names.length)
            return;
        let idx = names.indexOf(selectedAppName);
        if (idx === -1)
            idx = 0;
        const newIdx = Math.max(0, Math.min(names.length - 1, idx + delta));
        selectedAppName = names[newIdx];

        // GridView's own positionViewAtIndex handles scrolling the
        // selection into view — no manual contentY math needed (that
        // also isn't reliably possible anymore now that GridView does
        // its own internal virtualized scrolling instead of living
        // inside an outer ScrollView).
        grid.positionViewAtIndex(newIdx, GridView.Contain);
    }

    function _resetSelection() {
        const names = root.displayApps.map(a => a.name);
        if (names.length > 0 && names.indexOf(root.selectedAppName) === -1)
            root.selectedAppName = names[0];
        else if (names.length === 0)
            root.selectedAppName = "";
    }

    implicitHeight: 440
    implicitWidth: 640

    Component.onCompleted: root._resetSelection()
    onSearchTextChanged: root._resetSelection()
    onDisplayAppsChanged: root._resetSelection()

    RowLayout {
        anchors.fill: parent
        spacing: 16

        SideMenu {
            Layout.fillHeight: true
            visible: !root.isSearching
            menuModel: root.sideMenuModel
            currentIndex: root.sideMenuModel.findIndex(m => m.key === ShellState.launcherAppsSubTab)
            onTabClicked: idx => {
                ShellState.launcherAppsSubTab = root.sideMenuModel[idx].key;
            }
        }

        // ── Grid area ────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                visible: root.displayApps.length === 0
                text: root.isSearching ? "No matching apps" : "Nothing here yet"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13
                opacity: 0.4
            }

            GridView {
                id: grid
                anchors.fill: parent
                clip: true
                visible: root.displayApps.length > 0
                cellWidth: width / root.columns
                cellHeight: 110
                model: root.displayApps

                // The whole point of using GridView instead of
                // Flow+Repeater: only visible rows + this buffer get
                // instantiated/decoded, not the entire installed-apps
                // list at once.
                cacheBuffer: 220

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Item {
                    id: appItem

                    required property var modelData
                    readonly property var appData: modelData
                    readonly property string appName: modelData.name
                    property bool isSelected: root.selectedAppName === modelData.name
                    readonly property bool isHoveredTile: tileHover.hovered

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        color: Theme.selected
                        opacity: appItem.isSelected ? 0.22 : (appItem.isHoveredTile ? 0.1 : 0)
                        radius: Theme.radius
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                        anchors {
                            fill: parent
                            margins: 6
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            source: DesktopEntryService.resolveIconPath(modelData.icon)
                            sourceSize: Qt.size(48, 48)
                            asynchronous: true
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: grid.cellWidth - 16
                            color: Theme.foreground
                            elide: Text.ElideRight
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            maximumLineCount: 2
                            opacity: 0.85
                            text: modelData.name
                            wrapMode: Text.Wrap
                        }
                    }

                    // Pin/favorite toggle — purely visual here; the
                    // dedicated MouseArea below handles the actual
                    // click, geometrically excluded from appMouse (no
                    // blocker/z-order tricks).
                    IconButton {
                        id: favBtn
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: 10
                        }
                        size: 22
                        iconSize: 12
                        icon: AppUsageService.isFavorite(modelData.name) ? "star" : "star-off"
                        visible: appItem.isHoveredTile || AppUsageService.isFavorite(modelData.name)
                        normalColor: Theme.backgroundAlt
                        hoverColor: Theme.selected
                        activeColor: Theme.selected
                        isActive: AppUsageService.isFavorite(modelData.name)
                    }

                    HoverHandler {
                        id: tileHover
                    }

                    // Launch click zone — geometrically excludes the
                    // star's corner (topMargin clears it).
                    MouseArea {
                        id: appMouse
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            topMargin: 42
                        }
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root._launch(modelData)
                        onEntered: root.selectedAppName = modelData.name
                    }

                    // Dedicated, non-overlapping click zone for the star.
                    MouseArea {
                        anchors {
                            top: parent.top
                            right: parent.right
                        }
                        width: 42
                        height: 42
                        visible: favBtn.visible
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AppUsageService.toggleFavorite(modelData.name)
                    }
                }
            }
        }
    }
}
