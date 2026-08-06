pragma ComponentBehavior: Bound
import QtQuick
import qs.core
import qs.services
import "panels"
import "panels/DockerManager" as DockerNS // adjust path once files are physically moved
import "panels/Settings" as SettingsNS   // ditto

// Top-level content host for the Dashboard drawer — the single place
// that decides which of the 7 top-level components is on screen,
// driven entirely by ShellState.dashboardActiveComponent:
//
//   "tabs"       — info dashboard (TabsComponent)
//   "search"     — unified search/launcher (SearchComponent) — also
//                  covers the classic "app launcher" experience,
//                  scoped to the "apps" provider (browse mode until you
//                  type, same grid AppLauncherPanel already shows there)
//   "docker"     — Docker Manager
//   "sysmon"     — System Monitor
//   "settings"   — Shell & Hyprland settings
//   "screenshot" — capture mode picker (full/window/area/delay)
//   "record"     — screen recording mode picker + recording indicator
//
// docker/sysmon/settings/screenshot/record used to live NESTED inside
// SearchComponent or a separate QuickActions bottom drawer — they're
// peers of "search" now instead, rendered directly here with no
// search-bar chrome at all. None of them know about each other or
// about search; this file is the only place that decides which one is
// showing. screenshot/record are deliberately small/compact (no
// anchors.fill on their own root — see their own header comments) —
// unlike docker/sysmon/settings, they're quick popup-style pickers,
// not persistent content-heavy tools, so the drawer shrinking to fit
// them is the intended look, not a bug.
//
// (There used to be a 4th standalone component here, "appLauncherFull"
// — a search-bar-less full app grid. Removed: it was a strict subset
// of "search" scoped to "apps", which already shows the exact same
// grid when the query is empty, PLUS lets you type — the search-bar-
// less version could never offer that. See ShellState.qml's own note
// on this for the full reasoning.)
Item {
    id: wrapper

    implicitWidth: pageLoader.item?.implicitWidth ?? 0
    implicitHeight: pageLoader.item?.implicitHeight ?? 0

    readonly property var _componentMap: ({
            "tabs": tabsComp,
            "search": searchComp,
            "docker": dockerComp,
            "sysmon": sysmonComp,
            "settings": settingsComp,
            "screenshot": screenshotComp,
            "record": recordComp
        })

    Component {
        id: tabsComp
        TabsComponent {}
    }
    Component {
        id: searchComp
        SearchComponent {}
    }
    Component {
        id: dockerComp
        DockerNS.DockerManager {
            color: Theme.background
        }
    }
    Component {
        id: sysmonComp
        SystemMonitorTool {}
    }
    Component {
        id: settingsComp
        SettingsNS.Settings {}
    }
    Component {
        id: screenshotComp
        ScreenshotPanel {}
    }
    Component {
        id: recordComp
        RecordPanel {}
    }

    AnimLoader {
        id: pageLoader
        anchors.fill: parent
        sourceComp: wrapper._componentMap[ShellState.dashboardActiveComponent] ?? tabsComp
    }
}
