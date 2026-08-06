import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services

BarWidget {
    id: clockWidget

    property bool opened: false

    bgColor: "transparent"
    spacing: 8

    // ── Main click zone: calendar + date/time → toggle Tabs ────────
    // Own Item + own Hover/TapHandler, spatially separate from the
    // status-icon cluster below — a single widget-wide TapHandler
    // (what this used to be) would overlap with each icon's own
    // click target, same class of bug as SearchResultRow's actions
    // vs. row-activation area earlier in this shell's cleanup.
    Item {
        id: mainArea
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: mainRow.implicitWidth
        implicitHeight: mainRow.implicitHeight

        RowLayout {
            id: mainRow
            anchors.fill: parent
            spacing: 8

            LucideIcon {
                Layout.alignment: Qt.AlignVCenter
                color: Theme.selected
                size: 16
                icon: "calendar"
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                color: Theme.foreground
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 14
                // Was sysClock.date from a locally-owned SystemClock —
                // now reads from the shared TimeService singleton (see
                // services/TimeService.qml) instead of owning its own
                // clock.
                text: Qt.formatDateTime(TimeService.date, "ddd dd MMM • HH:mm")
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
            onTapped: {
                const screenName = QsWindow.window?.screen?.name ?? "";
                ShellState.toggleDashboardTabs(screenName);
            }
        }
    }

    Item {
        height: 1
        width: 4
    }

    // ── Status icon cluster — each icon is its own clickable zone,
    // conditionally visible, jumping straight to whatever it
    // represents. Order: media, resumable tool, notifications
    // (rightmost/most attention-grabbing, matches its badge). ───────
    RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // Media playing indicator
        Item {
            Layout.alignment: Qt.AlignVCenter
            visible: MediaService.isPlaying
            height: 20
            width: 20

            LucideIcon {
                anchors.centerIn: parent
                color: Theme.selected
                size: 16
                icon: "music"
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: {
                    const screenName = QsWindow.window?.screen?.name ?? "";
                    ShellState.toggleDashboardTab(screenName, 1); // Media tab
                }
            }
        }

        // "You left something open" indicator — docker/sysmon/settings
        // (see ShellState.dashboardResumableComponent). Left-click
        // jumps back into it; right-click just dismisses the reminder
        // without touching whatever the dashboard currently shows.
        Item {
            id: resumableIndicator
            Layout.alignment: Qt.AlignVCenter
            visible: ShellState.dashboardHasResumableComponentActive
            height: 20
            width: 20

            readonly property var _icons: ({
                    "docker": "container",
                    "sysmon": "activity",
                    "settings": "settings"
                })

            LucideIcon {
                anchors.centerIn: parent
                color: Theme.selected
                size: 16
                icon: resumableIndicator._icons[ShellState.dashboardResumableComponent] ?? "circle"
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    const screenName = QsWindow.window?.screen?.name ?? "";
                    ShellState.openDashboardComponent(screenName, ShellState.dashboardResumableComponent);
                }
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: ShellState.forgetResumableComponent()
            }
        }

        // Notification bell
        Item {
            Layout.alignment: Qt.AlignVCenter
            visible: NotificationService.notifications.length > 0
            height: 20
            width: 20

            LucideIcon {
                anchors.centerIn: parent
                color: Theme.selected
                size: 16
                icon: "bell"
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: -6
                anchors.top: parent.top
                anchors.topMargin: -4
                color: Theme.color1
                height: 14
                radius: 7
                width: 14

                Text {
                    anchors.centerIn: parent
                    color: Theme.background
                    font.bold: true
                    font.pixelSize: 9
                    text: NotificationService.notifications.length
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: {
                    const screenName = QsWindow.window?.screen?.name ?? "";
                    ShellState.toggleDashboardTab(screenName, 3); // Notifications tab
                }
            }
        }
    }
}
