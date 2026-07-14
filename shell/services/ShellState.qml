pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool appLauncherOpened: false
    property bool controlCenterOpened: false
    property int currentDashboardTab: 0
    property int currentProductivityTab: 0
    property bool dashboardOpened: false
    property bool isLocked: false
    property bool powerMenuOpened: false
    property string quickAction: ""
    property bool quickActionsOpened: false
    property bool systemDrawerOpened: false
}
