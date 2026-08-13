import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services

Item {
    id: root

    readonly property real uiScale: Theme.scaleFor(QsWindow.window?.screen)

    implicitHeight: parent.height

    readonly property bool nonTabsActive: ShellState.dashboardActiveComponent !== "tabs"
    readonly property alias contentRow: contentRow

    property bool moreExpanded: false

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 12 * root.uiScale

        IconButton {
            visible: ShellState.dashboardActiveComponent !== "search"
            icon: "search"
            size: 40 * root.uiScale
            iconSize: 17 * root.uiScale
            radius: Theme.radius
            hoverColor: Theme.selected
            normalColor: Theme.background
            idleOpacity: 0.7
            tooltipText: "Search"
            hoverSolid: true
            alwaysBorder: true
            borderColor: Theme.borderColor
            onTapped: ShellState.openDashboardSearch(ShellState.activeScreenName)
        }

        // ── Mode toggle: Search entry point / back to Tabs ────────
        IconButton {
            visible: ShellState.dashboardActiveComponent !== "tabs"
            icon: root.nonTabsActive ? "layout-dashboard" : "search"
            size: 40 * root.uiScale
            iconSize: 17 * root.uiScale
            radius: Theme.radius
            hoverColor: Theme.selected
            normalColor: Theme.background
            idleOpacity: 0.7
            tooltipText: root.nonTabsActive ? "Back to Dashboard" : "Search Apps"
            hoverSolid: true
            alwaysBorder: true
            borderColor: Theme.borderColor
            onTapped: {
                if (root.nonTabsActive)
                    ShellState.openDashboardTabs(ShellState.activeScreenName);
                else
                    ShellState.openDashboardSearch(ShellState.activeScreenName);
            }
        }

        // ── Username (center) ────────────────────────────────────
        Rectangle {
            implicitWidth: userRow.implicitWidth + (24 * root.uiScale)
            implicitHeight: 36 * root.uiScale
            radius: Theme.radius
            color: Theme.background
            border.width: Theme.widgetBorderWidth
            border.color: Theme.borderColor

            RowLayout {
                id: userRow
                anchors.centerIn: parent
                spacing: 8 * root.uiScale

                LucideIcon {
                    icon: "user"
                    size: 16 * root.uiScale
                    color: Theme.foreground
                    opacity: 0.5
                }
                Text {
                    text: SystemInfo.username
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 16 * root.uiScale
                    font.bold: true
                    opacity: 0.75
                }
            }
        }

        // ── Resumable-tool indicator ──────────────────────────────
        Item {
            id: resumableIndicator
            visible: ShellState.dashboardHasResumableComponentActive
            implicitWidth: 40 * root.uiScale
            implicitHeight: 40 * root.uiScale

            readonly property var _icons: ({
                    "docker": "container",
                    "sysmon": "activity",
                    "settings": "settings",
                    "git": "git-branch"
                })

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: resumableHover.hovered ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15) : Theme.background
                border.width: Theme.widgetBorderWidth
                border.color: Theme.borderColor
            }

            LucideIcon {
                anchors.centerIn: parent
                icon: resumableIndicator._icons[ShellState.dashboardResumableComponent] ?? "circle"
                size: 17 * root.uiScale
                color: Theme.selected
                opacity: 0.9
            }

            HoverHandler {
                id: resumableHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: ShellState.openDashboardComponent(ShellState.activeScreenName, ShellState.dashboardResumableComponent)
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: ShellState.forgetResumableComponent()
            }

            StyledToolTip {
                visible: resumableHover.hovered
                text: "Resume " + ShellState.dashboardResumableComponent + " · right-click to dismiss"
            }
        }

        // ── "More" ─────────────────────────────────────────────────
        IconButton {
            icon: "zap"
            size: 40 * root.uiScale
            iconSize: 17 * root.uiScale
            radius: Theme.radius
            hoverColor: Theme.selected
            normalColor: Theme.background
            activeColor: Theme.selected
            isActive: root.moreExpanded
            idleOpacity: 0.7
            tooltipText: "More"
            hoverSolid: true
            alwaysBorder: true
            borderColor: Theme.borderColor
            onTapped: root.moreExpanded = !root.moreExpanded
        }

        // ── Screenshot ─────────────────────────────────────────────
        IconButton {
            visible: root.moreExpanded
            icon: "camera"
            size: 40 * root.uiScale
            iconSize: 17 * root.uiScale
            radius: Theme.radius
            hoverColor: Theme.selected
            normalColor: Theme.background
            idleOpacity: 0.7
            tooltipText: "Screenshot"
            hoverSolid: true
            alwaysBorder: true
            borderColor: Theme.borderColor
            onTapped: {
                root.moreExpanded = false;
                ShellState.openScreenshot(ShellState.activeScreenName);
            }
        }

        // ── Record ─────────────────────────────────────────────────
        IconButton {
            visible: root.moreExpanded
            icon: "circle-dot"
            size: 40 * root.uiScale
            iconSize: 17 * root.uiScale
            radius: Theme.radius
            hoverColor: Theme.selected
            normalColor: Theme.background
            idleOpacity: 0.7
            tooltipText: "Record Screen"
            hoverSolid: true
            alwaysBorder: true
            borderColor: Theme.borderColor
            onTapped: {
                root.moreExpanded = false;
                ShellState.openRecord(ShellState.activeScreenName);
            }
        }

        // ── Color Picker ───────────────────────────────────────────
        IconButton {
            visible: root.moreExpanded
            icon: "pipette"
            size: 40 * root.uiScale
            iconSize: 17 * root.uiScale
            radius: Theme.radius
            hoverColor: Theme.selected
            normalColor: Theme.background
            idleOpacity: 0.7
            tooltipText: "Pick a Color"
            hoverSolid: true
            alwaysBorder: true
            borderColor: Theme.borderColor
            onTapped: {
                root.moreExpanded = false;
                ShellState.closeDashboard();
                SearchProviders.runColorPicker();
            }
        }
    }
}
