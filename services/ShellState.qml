pragma Singleton
import QtQuick

QtObject {
    id: root

    property int activeWidgetPopups: 0
    readonly property bool anyPopupOpen: (activeWidgetPopups > 0)
    property bool controlCenterOpened: false
    property int currentDashboardTab: 0
    property bool launcherOpened: false
    property bool powerMenuOpened: false
    property bool quakeTerminalOpened: false
    property bool topDashboardOpened: false
}
