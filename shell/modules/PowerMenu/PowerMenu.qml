import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

PanelWindow {
    id: powerMenu

    visible: ShellState.powerMenuOpened
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    readonly property real uiScale: Theme.scaleFor(screen)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Shortcut {
        sequence: "Escape"
        onActivated: ShellState.powerMenuOpened = false
    }

    GlassBackground {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.4
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.powerMenuOpened = false
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 60 * powerMenu.uiScale

        // ── Header ────────────────────────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10 * powerMenu.uiScale

            Text {
                text: "Goodbye, " + SystemInfo.username
                font.family: Theme.fontName
                font.pixelSize: 32 * powerMenu.uiScale
                font.bold: true
                color: Theme.selected
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: SystemInfo.osName + " • " + SystemInfo.uptime
                font.family: Theme.fontName
                font.pixelSize: 16 * powerMenu.uiScale
                color: Theme.selected
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // ── Action buttons ────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 40 * powerMenu.uiScale

            Repeater {
                model: [
                    {
                        icon: "power",
                        label: "Shutdown",
                        action: () => PowerService.poweroff(),
                        color: Theme.color1
                    },
                    {
                        icon: "refresh-cw",
                        label: "Reboot",
                        action: () => PowerService.reboot(),
                        color: Theme.color2
                    },
                    {
                        icon: "moon",
                        label: "Suspend",
                        action: () => PowerService.suspend(),
                        color: Theme.color3
                    },
                    {
                        icon: "lock",
                        label: "Lock",
                        action: () => PowerService.lock(),
                        color: Theme.color4
                    },
                    {
                        icon: "log-out",
                        label: "Logout",
                        action: () => PowerService.logout(),
                        color: Theme.color5
                    },
                ]

                CircularActionButton {
                    icon: modelData.icon
                    showLabel: false
                    diameter: 140
                    iconSize: 48
                    uiScale: powerMenu.uiScale

                    hoverColor: modelData.color
                    activeColor: modelData.color
                    tooltipText: modelData.label

                    onTapped: {
                        ShellState.powerMenuOpened = false;
                        modelData.action();
                    }
                }
            }
        }
    }
}
