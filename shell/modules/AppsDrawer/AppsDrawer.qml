import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"

BaseDrawer {
    id: launcherWindow

    cornerMode: true
    anchors.top: true
    margins.top: Theme.barHeight
    edge: Qt.LeftEdge
    opened: ShellState.launcherOpened
    panelHeight: 650
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
                        text: SystemInfo.username
                    }
                    RowLayout {
                        spacing: 6

                        LucideIcon {
                            size: 18
                            icon: "clock"
                            color: Theme.selected
                        }

                        Text {
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 18
                            opacity: 0.7
                            text: SystemInfo.uptime
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
