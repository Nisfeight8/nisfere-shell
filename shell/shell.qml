// @pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.NotificationPopup
import qs.modules.Bar
import qs.modules.AppsDrawer
import qs.modules.ScreenBorder
import qs.modules.PowerMenu
import qs.modules.ControlCenter
import qs.modules.MenuDrawer
import qs.modules.Locker

import qs.modules.Dashboard
import qs.services
import qs.core

ShellRoot {
    id: root

    property IpcHandler ipcHandler2: IpcHandler {

        function trigger(): void {
            ShellState.isLocked = true;
        }
        target: "nisfere-lock"
    }

    ScreenBorder {}
    NotificationPopup {}
    Bar {}
    AppsDrawer {}
    ControlCenter {}
    MenuDrawer {}
    Dashboard {}

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
                        LockerService.start();
                    } else {
                        LockerService.stop();
                    }
                }
            }
        }
    }
}
