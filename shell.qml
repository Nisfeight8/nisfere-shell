// @pragma UseQApplication

import QtQuick
import Quickshell
import qs.modules.NotificationPopup
import qs.modules.Bar
import qs.modules.LeftDrawer
import qs.modules.ScreenBorder
import qs.modules.PowerMenu
import qs.modules.QuakeConsole
import qs.modules.ControlCenter

import qs.modules.TopDashboard

ShellRoot {
    id: root

    ScreenBorder {
    }
    NotificationPopup {
    }
    Bar {
    }
    LazyLoader {
        id: leftDrawerLoader

        loading: true

        Binding {
            property: "active"
            restoreMode: Binding.RestoreNone
            target: leftDrawerLoader
            value: true
            when: ShellState.launcherOpened
        }
        LeftDrawer {
        }
    }
    LazyLoader {
        id: controlCenterLoader

        loading: true

        Binding {
            property: "active"
            restoreMode: Binding.RestoreNone
            target: controlCenterLoader
            value: true
            when: ShellState.controlCenterOpened
        }
        ControlCenter {
        }
    }
    LazyLoader {
        id: quakeConsoleLoader

        loading: true

        Binding {
            property: "active"
            restoreMode: Binding.RestoreNone
            target: quakeConsoleLoader
            value: true
            when: ShellState.quakeTerminalOpened
        }
        QuakeConsole {
        }
    }
    LazyLoader {
        id: topDashboardLoader

        loading: true
        
        Binding {
            property: "active"
            restoreMode: Binding.RestoreNone
            target: topDashboardLoader
            value: true
            when: ShellState.topDashboardOpened
        }
        TopDashboard {
        }
    }

    // Loader {
    //     active: true

    //     sourceComponent: PowerMenu {
    //     }
    // }
}
