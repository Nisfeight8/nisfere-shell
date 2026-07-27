pragma Singleton
import Quickshell

import QtQuick
import qs.services

Singleton {
    id: root

    // Which screen "owns" whichever UI is currently open — every
    // per-screen drawer/loader will additionally gate on
    // `screen.name === activeScreenName` once ScreenBorder goes
    // multi-screen, so hovering an edge on one screen doesn't pop the
    // same UI up on every screen at once.
    property string activeScreenName: ""

    // For IPC-triggered opens (keybinds), which don't have a "which
    // screen did this come from" of their own — HyprlandData.monitors
    // already carries `focused` per hyprctl, so this is free, no new
    // data source needed.
    readonly property string focusedScreenName: HyprlandData.monitors.find(m => m.focused)?.name ?? ""

    property bool isLocked: false
    property bool powerMenuOpened: false

    property bool controlCenterOpened: false
    property int controlCenterPageIndex: 0
    property bool systemDrawerOpened: false

    property bool appLauncherOpened: false
    property int launcherActiveTab: 0
    property string launcherActiveTool: ""
    property string launcherAppsSubTab: "all"
    property string pendingLauncherTool: ""

    property bool dashboardOpened: false
    property int currentDashboardTab: 0
    property int currentProductivityTab: 0

    property string quickAction: ""
    property bool quickActionsOpened: false

    property int workspacesPerMonitor: ThemeState.shared.workspacesPerMonitor
    property bool overviewOpen: false
    property int overviewRows: 2
    property int overviewColumns: workspacesPerMonitor / overviewRows
    property bool overviewPreviewsEnabled: true
    property bool overviewLivePreviews: false

    // ── Open/close/toggle methods ───────────────────────────────────
    // Callers (hover wiring, IPC handlers) call these instead of
    // mutating the booleans directly, so "which screen asked for
    // this" is always recorded consistently in ONE place instead of
    // every caller having to remember to set activeScreenName itself.

    function openDashboard(screenName) {
        activeScreenName = screenName;
        dashboardOpened = true;
    }
    function closeDashboard() {
        dashboardOpened = false;
    }
    function toggleDashboard(screenName) {
        if (dashboardOpened && activeScreenName === screenName)
            closeDashboard();
        else
            openDashboard(screenName);
    }

    function openControlCenter(screenName) {
        activeScreenName = screenName;
        controlCenterOpened = true;
    }
    function closeControlCenter() {
        controlCenterOpened = false;
    }
    function toggleControlCenter(screenName) {
        if (controlCenterOpened && activeScreenName === screenName)
            closeControlCenter();
        else
            openControlCenter(screenName);
    }

    function openSystemDrawer(screenName) {
        activeScreenName = screenName;
        systemDrawerOpened = true;
    }
    function closeSystemDrawer() {
        systemDrawerOpened = false;
    }
    function toggleSystemDrawer(screenName) {
        if (systemDrawerOpened && activeScreenName === screenName)
            closeSystemDrawer();
        else
            openSystemDrawer(screenName);
    }

    function openQuickActions(screenName, action) {
        activeScreenName = screenName;
        if (action !== undefined)
            quickAction = action;
        quickActionsOpened = true;
    }
    function closeQuickActions() {
        quickActionsOpened = false;
    }
    function toggleQuickActions(screenName, action) {
        if (quickActionsOpened && activeScreenName === screenName && (action === undefined || quickAction === action))
            closeQuickActions();
        else
            openQuickActions(screenName, action);
    }

    function openAppLauncher(screenName) {
        activeScreenName = screenName;
        appLauncherOpened = true;
    }
    function closeAppLauncher() {
        appLauncherOpened = false;
    }
    function toggleAppLauncher(screenName) {
        if (appLauncherOpened && activeScreenName === screenName)
            closeAppLauncher();
        else
            openAppLauncher(screenName);
    }

    function openOverview(screenName) {
        activeScreenName = screenName;
        overviewOpen = true;
    }
    function closeOverview() {
        overviewOpen = false;
    }
    function toggleOverview(screenName) {
        if (overviewOpen && activeScreenName === screenName)
            closeOverview();
        else
            openOverview(screenName);
    }

    function openPowerMenu(screenName) {
        activeScreenName = screenName;
        powerMenuOpened = true;
    }
    function closePowerMenu() {
        powerMenuOpened = false;
    }
    function togglePowerMenu(screenName) {
        if (powerMenuOpened && activeScreenName === screenName)
            closePowerMenu();
        else
            openPowerMenu(screenName);
    }
}
