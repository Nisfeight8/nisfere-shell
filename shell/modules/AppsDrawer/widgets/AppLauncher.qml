import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.core
import qs.services

Item {
    id: launcherRoot

    Layout.fillHeight: true
    Layout.fillWidth: true

    property int columns: 4
    property string selectedAppName: ""
    Connections {
        target: ShellState
        function onLauncherOpenedChanged() {
            if (ShellState.launcherOpened) {
                searchInput.forceActiveFocus();
                let apps = DesktopEntries.applications;
                selectedAppName = apps.length > 0 ? apps[0].name : "";
            } else {
                searchInput.text = "";
                selectedAppName = "";
            }
        }
    }

    function getVisibleApps() {
        let result = [];
        for (let i = 0; i < appsRepeater.count; i++) {
            let item = appsRepeater.itemAt(i);
            if (item && item.isMatch) {
                result.push({
                    name: item.appName
                });
            }
        }
        return result;
    }

    function navigate(delta) {
        let visible = getVisibleApps();
        if (visible.length === 0)
            return;

        let idx = visible.findIndex(app => app.name === selectedAppName);
        if (idx === -1)
            idx = 0;

        let newIdx = Math.max(0, Math.min(visible.length - 1, idx + delta));
        selectedAppName = visible[newIdx].name;
    }

    function launchSelected() {
        if (selectedAppName === "")
            return;

        for (let i = 0; i < appsRepeater.count; i++) {
            let item = appsRepeater.itemAt(i);
            if (item && item.appName === selectedAppName) {
                item.appData.execute();
                ShellState.launcherOpened = false;
                break;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        // ── Search bar ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            border.color: searchInput.activeFocus ? Theme.selected : "transparent"
            border.width: Theme.widgetBorderWidth
            color: Theme.backgroundAlt
            height: 40
            radius: Theme.radius

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    opacity: 0.6
                    text: ""
                }

                TextInput {
                    id: searchInput

                    Layout.fillWidth: true
                    clip: true
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 14

                    onTextChanged: {
                        let visible = launcherRoot.getVisibleApps();
                        if (visible.length > 0) {
                            let idx = visible.findIndex(app => app.name === launcherRoot.selectedAppName);
                            if (idx === -1) {
                                launcherRoot.selectedAppName = visible[0].name;
                            }
                        } else {
                            launcherRoot.selectedAppName = "";
                        }
                    }

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Up) {
                            launcherRoot.navigate(-launcherRoot.columns);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            launcherRoot.navigate(launcherRoot.columns);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left) {
                            if (cursorPosition === 0) {
                                launcherRoot.navigate(-1);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Right) {
                            if (cursorPosition === text.length) {
                                launcherRoot.navigate(1);
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            launcherRoot.launchSelected();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            ShellState.launcherOpened = false;
                            event.accepted = true;
                        }
                    }

                    Text {
                        color: Theme.foreground
                        font.family: Theme.fontName
                        opacity: 0.4
                        text: "Search applications..."
                        visible: !searchInput.text && !searchInput.activeFocus
                    }
                }
            }
        }

        // ── Apps Grid ──────────────────────────────────────────────
        ScrollView {
            id: appsScrollView

            Layout.fillHeight: true
            Layout.fillWidth: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            clip: true

            Flow {
                id: appsFlow

                spacing: 0
                width: appsScrollView.width

                Repeater {
                    id: appsRepeater
                    model: DesktopEntries.applications

                    delegate: Item {
                        id: appDelegate

                        readonly property string appName: modelData.name
                        readonly property var appData: modelData

                        readonly property bool isMatch: searchInput.text === "" || modelData.name.toLowerCase().includes(searchInput.text.toLowerCase())
                        readonly property bool isSelected: launcherRoot.selectedAppName === modelData.name

                        clip: true
                        height: isMatch ? 110 : 0
                        width: isMatch ? (appsFlow.width / launcherRoot.columns) : 0
                        visible: isMatch

                        onIsSelectedChanged: {
                            if (!isSelected || !isMatch)
                                return;
                            let itemY = appDelegate.mapToItem(appsFlow, 0, 0).y;
                            let scrollY = appsScrollView.contentItem.contentY;
                            let viewH = appsScrollView.height;
                            if (itemY < scrollY)
                                appsScrollView.contentItem.contentY = itemY;
                            else if (itemY + 110 > scrollY + viewH)
                                appsScrollView.contentItem.contentY = itemY + 110 - viewH;
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 6
                            color: Theme.selected
                            opacity: isSelected ? 0.25 : (appMouse.containsMouse ? 0.12 : 0)
                            radius: Theme.radius

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Image {
                                Layout.alignment: Qt.AlignHCenter
                                source: Quickshell.iconPath(modelData.icon)
                                sourceSize.height: 48
                                sourceSize.width: 48
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.maximumWidth: (appsFlow.width / launcherRoot.columns) - 16
                                color: Theme.foreground
                                elide: Text.ElideRight
                                font.family: Theme.fontName
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                maximumLineCount: 2
                                opacity: 0.8
                                text: modelData.name
                                wrapMode: Text.Wrap
                            }
                        }

                        MouseArea {
                            id: appMouse

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onEntered: launcherRoot.selectedAppName = modelData.name
                            onClicked: {
                                modelData.execute();
                                ShellState.launcherOpened = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
