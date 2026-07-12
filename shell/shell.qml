// @pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.NotificationPopup
import qs.modules.Bar
import qs.modules.SystemDrawer
import qs.modules.ScreenBorder
import qs.modules.PowerMenu
import qs.modules.ControlCenter
import qs.modules.QuickActionsDrawer
import qs.modules.Locker
import qs.modules.Osd
import qs.modules.AreaPicker
import qs.modules.CentralLauncher

import qs.modules.Dashboard
import qs.services
import qs.core

ShellRoot {
    id: root
    property var _internalNotif: InternalNotificationService
    property IpcHandler ipcHandler: IpcHandler {

        function trigger(): void {
            ShellState.isLocked = true;
        }
        function forceRestart() {
            LockerService.restart();      // test PAM restart directly, no lock/unlock involved
        }
        target: "nisfere-lock"
    }
    AreaPicker {}
    ScreenBorder {}
    NotificationPopup {}
    Bar {}
    OSD {}
    SystemDrawer {}
    ControlCenter {}
    QuickActionsDrawer {}
    Dashboard {}
    CentralLauncher {}
    LazyLoader {
        id: powerMenuLoader

        activeAsync: ShellState.powerMenuOpened
        PowerMenu {}
    }

    LazyLoader {
        id: lockerLoader
        loading: true
        activeAsync: ShellState.isLocked

        Locker {
            id: locker
            property Connections _con: Connections {
                target: ShellState

                function onIsLockedChanged() {
                    if (ShellState.isLocked) {
                        LockerService.restart();
                    } else {
                        LockerService.stop();
                    }
                }
            }
        }
    }
}
