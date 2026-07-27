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
        spacing: 60

        // ── Header ────────────────────────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Text {
                text: "Goodbye, " + SystemInfo.username
                font.family: Theme.fontName
                font.pixelSize: 32
                font.bold: true
                color: Theme.selected
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: SystemInfo.osName + " • " + SystemInfo.uptime
                font.family: Theme.fontName
                font.pixelSize: 16
                color: Theme.selected
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // ── Action buttons ────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 40

            Repeater {
                // Was inline `cmd: [...]` arrays duplicating the exact
                // same systemctl/loginctl/hyprshutdown commands now
                // centralized in PowerService.qml — action is a direct
                // function reference (plain JS array literals can hold
                // these fine), so there's one source of truth for what
                // each of these commands actually is.
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
                    showLabel: false          // tooltip only, no permanent label
                    diameter: 140
                    iconSize: 48

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
