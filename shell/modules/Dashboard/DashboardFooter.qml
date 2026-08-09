import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// Footer strip content — lives inside FooterDrawer's footerItem.
// Left: mode toggle (Search <-> Tabs). Center: current username
// (SystemInfo). Right: quick-action shortcuts + resumable-tool
// indicator + "more" reveal.
Item {
    id: root

    implicitHeight: parent.height

    // True whenever some NON-tabs page is active — search, or any of
    // the standalone tools (docker/sysmon/settings/screenshot/record).
    // Written as "not tabs" (rather than "is search") so every current
    // and future non-tabs component falls under the same toggle
    // without needing another branch here.
    readonly property bool nonTabsActive: ShellState.dashboardActiveComponent !== "tabs"
    readonly property alias contentRow: contentRow

    // "more" reveal state — inline, not a Popup (see chat: Popups
    // reparent outside the drawer's masked item tree, same reason
    // ProviderPicker stopped being one). Revealing more icons just
    // means more children inside this SAME contentRow, so the
    // footer's mask (footerMaskTarget, bound to contentRow's own
    // bounding box) grows to match automatically — no extra plumbing.
    property bool moreExpanded: false

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 12
        IconButton {
            visible: ShellState.dashboardActiveComponent !== "search"
            icon: "search"
            size: 40
            iconSize: 17
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
            size: 40
            iconSize: 17
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
            implicitWidth: userRow.implicitWidth + 24
            implicitHeight: 36
            radius: Theme.radius
            color: Theme.background
            border.width: Theme.widgetBorderWidth
            border.color: Theme.borderColor

            RowLayout {
                id: userRow
                anchors.centerIn: parent
                spacing: 8

                LucideIcon {
                    icon: "user"
                    size: 16
                    color: Theme.foreground
                    opacity: 0.5
                }
                Text {
                    text: SystemInfo.username
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 16
                    font.bold: true
                    opacity: 0.75
                }
            }
        }

        // ── Resumable-tool indicator — same pattern as the bar
        // clock's own indicator (see Clock.qml). Handy here too: if
        // you're already inside the Dashboard looking at e.g. Tabs,
        // no reason to go all the way out to the bar just to jump
        // back into a backgrounded Docker/SysMon/Settings session. ──
        Item {
            id: resumableIndicator
            visible: ShellState.dashboardHasResumableComponentActive
            implicitWidth: 40
            implicitHeight: 40

            readonly property var _icons: ({
                    "docker": "container",
                    "sysmon": "activity",
                    "settings": "settings"
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
                size: 17
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

        // ── "More" — reveals additional quick actions INLINE in this
        // same row (Color Picker today; room for more later) rather
        // than a Popup or a separate page. isActive mirrors the
        // expanded state so the button visually stays "pressed" while
        // open. ─────────────────────────────────────────────────────
        IconButton {
            icon: "zap"
            size: 40
            iconSize: 17
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

        // ── Screenshot — direct 1-click shortcut, no intermediate
        // step (see chat: this and Record get their own buttons
        // specifically because they're the ones you reach for most). ──
        IconButton {
            visible: root.moreExpanded
            icon: "camera"
            size: 40
            iconSize: 17
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
                ShellState.openScreenshot(ShellState.activeScreenName)
            }
        }

        // ── Record — same reasoning as Screenshot above ───────────
        IconButton {
            visible: root.moreExpanded
            icon: "circle-dot"
            size: 40
            iconSize: 17
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
                ShellState.openRecord(ShellState.activeScreenName)
            }
        }

        // Color Picker — a search PROVIDER (@pick), not a standalone
        // component like Screenshot/Record, so a plain
        // openDashboardSearch() here would land you on a one-result
        // list you'd still have to click — two taps instead of one.
        // SearchProviders.runColorPicker() is the direct entry point
        // that skips search entirely: same close-dashboard-then-run
        // delay the provider's own search result uses, just reachable
        // without faking a search interaction first.
        IconButton {
            visible: root.moreExpanded
            icon: "pipette"
            size: 40
            iconSize: 17
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
