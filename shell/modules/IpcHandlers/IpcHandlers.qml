import QtQuick
import Quickshell.Io
import qs.services

// All IPC handlers in one place, out of shell.qml. Each open/toggle
// goes through ShellState's methods (see ShellState.qml) — an IPC call
// has no "which screen did this come from" of its own, so it targets
// ShellState.focusedScreenName (whichever monitor Hyprland currently
// considers focused).
Item {
    id: root

    IpcHandler {
        target: "nisfere-lock"

        function trigger(): void {
            ShellState.isLocked = true;
        }
        function forceRestart(): void {
            LockerService.restart();      // test PAM restart directly, no lock/unlock involved
        }
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            ShellState.toggleOverview(ShellState.focusedScreenName);
        }
        function open(): void {
            ShellState.openOverview(ShellState.focusedScreenName);
        }
        function close(): void {
            ShellState.closeOverview();
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            ShellState.toggleAppLauncher(ShellState.focusedScreenName);
        }
        function open(): void {
            ShellState.openAppLauncher(ShellState.focusedScreenName);
        }
        function close(): void {
            ShellState.closeAppLauncher();
        }
    }

    IpcHandler {
        target: "powermenu"

        function toggle(): void {
            ShellState.togglePowerMenu(ShellState.focusedScreenName);
        }
        function open(): void {
            ShellState.openPowerMenu(ShellState.focusedScreenName);
        }
        function close(): void {
            ShellState.closePowerMenu();
        }
    }

    IpcHandler {
        target: "quickactions"

        function open(action: string): void {
            ShellState.openQuickActions(ShellState.focusedScreenName, action);
        }
        function close(): void {
            ShellState.closeQuickActions();
        }
        function toggle(action: string): void {
            ShellState.toggleQuickActions(ShellState.focusedScreenName, action);
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            ShellState.toggleDashboard(ShellState.focusedScreenName);
        }
        function open(): void {
            ShellState.openDashboard(ShellState.focusedScreenName);
        }
        function close(): void {
            ShellState.closeDashboard();
        }
        function openTab(index: int): void {
            ShellState.currentDashboardTab = index;
            ShellState.openDashboard(ShellState.focusedScreenName);
        }
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void {
            ShellState.toggleControlCenter(ShellState.focusedScreenName);
        }
        function open(): void {
            ShellState.openControlCenter(ShellState.focusedScreenName);
        }
        function close(): void {
            ShellState.closeControlCenter();
        }
    }
}
