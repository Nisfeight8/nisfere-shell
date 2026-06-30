import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.core
import qs.services
import "widgets"

BaseDrawer {
    id: launcherWindow

    readonly property var process: Process {
        id: userProcess

        command: ["sh", "-c", "whoami"]

        running: launcherWindow.opened

        stdout: SplitParser {
            onRead: raw => username = raw
        }
    }
    property string username: "User"

    function formatUsername(name) {
        if (!name)
            return "User";
        let cleanName = name.trim();
        return cleanName.charAt(0).toUpperCase() + cleanName.slice(1);
    }

    edge: Qt.LeftEdge
    opened: ShellState.launcherOpened
    panelHeight: Screen.height / 1.5
    panelWidth: Screen.width / 3.4

    onCloseRequest: ShellState.launcherOpened = false
    onOpenRequest: ShellState.launcherOpened = true
    onToggleRequest: ShellState.launcherOpened = !ShellState.launcherOpened

    contentComponent: Component {
        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Rectangle {
                    color: Theme.backgroundAlt
                    height: 64
                    layer.enabled: true
                    radius: 32
                    width: 64

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        source: ""
                        visible: source != ""
                    }

                    LucideIcon {
                        anchors.centerIn: parent
                        color: Theme.selected
                        size: 32
                        icon: "user"

                        visible: avatarImg.source == ""
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        color: Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 22
                        text: formatUsername(username)
                    }
                    RowLayout {
                        spacing: 6

                        Text {
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 14
                            text: ""
                        }
                        Text {
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 14
                            opacity: 0.7
                            text: "Up 2 hours, 15 mins"
                        }
                    }
                }
            }
            Rectangle {
                Layout.bottomMargin: 10
                Layout.fillWidth: true
                Layout.topMargin: 10
                color: Theme.backgroundAlt
                height: 2
                radius: 1
            }
            AppLauncher {
                id: appLauncher
            }
        }
    }
}
