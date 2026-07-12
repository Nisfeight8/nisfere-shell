import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.core
import qs.services

// AppLauncher adapted for CentralLauncher:
// - No internal search input (uses external searchText)
// - No internal Escape/close (parent handles it)
// - Exposes navigate() and launchSelected() for parent key handling
Item {
    id: root

    property int columns: 4
    property string searchText: ""
    property string selectedAppName: ""

    function _visibleApps() {
        let result = [];
        for (let i = 0; i < appsRepeater.count; i++) {
            let item = appsRepeater.itemAt(i);
            if (item?.isMatch)
                result.push(item.appName);
        }
        return result;
    }
    function launchSelected() {
        for (let i = 0; i < appsRepeater.count; i++) {
            let item = appsRepeater.itemAt(i);
            if (item?.appName === selectedAppName) {
                item.appData.execute();
                return true;
            }
        }
        return false;
    }
    function navigate(delta) {
        let visible = _visibleApps();
        if (!visible.length)
            return;
        let idx = visible.indexOf(selectedAppName);
        if (idx === -1)
            idx = 0;
        selectedAppName = visible[Math.max(0, Math.min(visible.length - 1, idx + delta))];
    }

    implicitHeight: 440
    implicitWidth: 520

    Component.onCompleted: {
        let apps = DesktopEntries.applications;
        selectedAppName = apps.count > 0 ? apps.values[0].name : "";
    }
    onSearchTextChanged: {
        let visible = _visibleApps();
        if (visible.length > 0) {
            let idx = visible.findIndex(a => a === selectedAppName);
            if (idx === -1)
                selectedAppName = visible[0];
        } else {
            selectedAppName = "";
        }
    }

    ScrollView {
        id: scroll

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        anchors.fill: parent
        clip: true

        Flow {
            id: flow

            spacing: 0
            width: scroll.width

            Repeater {
                id: appsRepeater

                model: DesktopEntries.applications

                delegate: Item {
                    id: appItem

                    property var appData: modelData
                    property string appName: modelData.name
                    property bool isMatch: root.searchText === "" || modelData.name.toLowerCase().includes(root.searchText.toLowerCase())
                    property bool isSelected: root.selectedAppName === modelData.name

                    clip: true
                    height: isMatch ? 110 : 0
                    visible: isMatch
                    width: isMatch ? flow.width / root.columns : 0

                    onIsSelectedChanged: {
                        if (!isSelected || !isMatch)
                            return;
                        let y = mapToItem(flow, 0, 0).y;
                        let cy = scroll.contentItem.contentY;
                        if (y < cy)
                            scroll.contentItem.contentY = y;
                        else if (y + 110 > cy + scroll.height)
                            scroll.contentItem.contentY = y + 110 - scroll.height;
                    }

                    Rectangle {
                        color: Theme.selected
                        opacity: appItem.isSelected ? 0.22 : (appMouse.containsMouse ? 0.1 : 0)
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
                            source: Quickshell.iconPath(modelData.icon)
                            sourceSize: Qt.size(48, 48)
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: flow.width / root.columns - 16
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
                    MouseArea {
                        id: appMouse

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: {
                            modelData.execute();
                            ShellState.appLauncherOpened = false;
                        }
                        onEntered: root.selectedAppName = modelData.name
                    }
                }
            }
        }
    }
}
