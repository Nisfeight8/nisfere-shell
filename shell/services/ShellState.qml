pragma Singleton
import QtQuick

QtObject {
    id: root
    property bool controlCenterOpened: false
    property int currentDashboardTab: 1
    property bool launcherOpened: false
    property bool powerMenuOpened: false
    property bool menuDrawerOpened: false
    property bool dashboardOpened: false
    property bool isLocked: false
}
