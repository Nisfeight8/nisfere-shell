pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.Bar
import qs.modules.Dashboard
import qs.modules.ControlCenter
import qs.modules.SystemDrawer
import qs.modules.Osd
import qs.modules.NotificationPopup
import qs.modules.WorkspaceOverview
import qs.modules.WallpaperOverlay

import qs.core
import qs.services

// One instance of everything below per screen (Variants). Each
// instance gets its own visualWindow + ExclusionZones bound to that
// specific screen via `screen: modelData`.
Variants {
    id: screenVariants
    model: Quickshell.screens

    Scope {
        id: rootScope
        required property var modelData
        readonly property var screen: modelData

        property real bezelSize: Theme.screenBorderSize
        readonly property real topBarHeight: Theme.barHeight

        // ---------------------------------------------------------
        // 1. Ο VISUAL WINDOW (μπάρα, drawers, overview, bezels)
        // ---------------------------------------------------------
        PanelWindow {
            id: visualWindow
            screen: rootScope.screen

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            // ── "Is this UI actually the one this screen owns?" ────
            // Every layer/focus decision below is gated on this — a
            // drawer being open somewhere doesn't affect a screen it
            // wasn't opened on.
            readonly property bool _isActiveScreen: screen && ShellState.activeScreenName === screen.name

            // ── Overlay layer ──────────────────────────────────────
            // Whether ANY currently-open UI on this screen wants to
            // sit above normal windows (WlrLayer.Overlay vs Top).
            // Sourced entirely from ShellState's semantic
            // dashboardWantsOverlayLayer / controlCenterWantsOverlayLayer
            // properties (see ShellState.qml) instead of re-deriving
            // tab-index/page-index conditions here — adding a new
            // sub-panel that needs this means one clause in ShellState,
            // not a hunt through this file.
            readonly property bool isAnyUIOpen: _isActiveScreen && (ShellState.dashboardWantsOverlayLayer || ShellState.overviewOpen || ShellState.controlCenterWantsOverlayLayer)

            // ── Keyboard focus split ────────────────────────────────
            // Three tiers, evaluated in order of "how much keyboard do
            // we need right now":
            //
            //   Exclusive — Overview, and Dashboard's "search" /
            //               "appLauncherFull" components (keyboard nav
            //               through results / side-menu / app grid).
            //   OnDemand  — anything with a single focusable field the
            //               user might click into (ControlCenter's
            //               wifi-password page, Dashboard's
            //               productivity to-do input, and the
            //               "docker"/"sysmon"/"settings" standalone
            //               tools) but that shouldn't steal focus just
            //               for being open.
            //   None      — plain read-only Tabs views (overview/media/
            //               weather/notifications tabs). These used to
            //               get OnDemand merely because dashboardOpened
            //               was true, with no actual focusable content
            //               to justify it — tightened so a hover-open
            //               dashboard can no longer touch keyboard
            //               focus at all unless something inside it
            //               genuinely needs it.
            //
            // Both tiers now come straight from ShellState's own
            // per-component focus-mode lookup (dashboardWantsExclusiveFocus/
            // dashboardWantsOnDemandFocus) — mutually exclusive by
            // construction there, so no "!needsExclusiveFocus" guard is
            // needed here anymore.
            readonly property bool needsExclusiveFocus: _isActiveScreen && (ShellState.overviewOpen || ShellState.dashboardWantsExclusiveFocus)
            readonly property bool needsOnDemandFocus: _isActiveScreen && (ShellState.dashboardWantsOnDemandFocus || ShellState.controlCenterWantsOnDemandFocus)

            // ── Fullscreen detection ──────────────────────────────────
            readonly property var _monitorData: screen ? HyprlandData.monitors.values.find(m => m.name === screen.name) : null

            readonly property bool hasFullscreen: screen ? HyprlandData.hasFullscreenOnScreen(screen.name) : false
            readonly property bool showingWallpaper: screen ? HyprlandData.isShowingWallpaper(screen.name) : false

            // ── Adjacent-monitor detection ─────────────────────────────

            function _yOverlaps(other) {
                if (!_monitorData || !other)
                    return false;
                const aTop = _monitorData.y, aBottom = _monitorData.y + _monitorData.height;
                const bTop = other.y, bBottom = other.y + other.height;
                return aTop < bBottom && bTop < aBottom;
            }
            function _xOverlaps(other) {
                if (!_monitorData || !other)
                    return false;
                const aLeft = _monitorData.x, aRight = _monitorData.x + _monitorData.width;
                const bLeft = other.x, bRight = other.x + other.width;
                return aLeft < bRight && bLeft < aRight;
            }
            readonly property bool hasMonitorToLeft: _monitorData ? HyprlandData.monitors.values.some(m => m.name !== _monitorData.name && Math.abs((m.x + m.width) - _monitorData.x) < 2 && _yOverlaps(m)) : false
            readonly property bool hasMonitorToRight: _monitorData ? HyprlandData.monitors.values.some(m => m.name !== _monitorData.name && Math.abs(m.x - (_monitorData.x + _monitorData.width)) < 2 && _yOverlaps(m)) : false
            readonly property bool hasMonitorAbove: _monitorData ? HyprlandData.monitors.values.some(m => m.name !== _monitorData.name && Math.abs((m.y + m.height) - _monitorData.y) < 2 && _xOverlaps(m)) : false
            readonly property bool hasMonitorBelow: _monitorData ? HyprlandData.monitors.values.some(m => m.name !== _monitorData.name && Math.abs(m.y - (_monitorData.y + _monitorData.height)) < 2 && _xOverlaps(m)) : false

            WlrLayershell.keyboardFocus: needsExclusiveFocus ? WlrKeyboardFocus.Exclusive : (needsOnDemandFocus ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)
            WlrLayershell.layer: (isAnyUIOpen || osd.shown || notificationPopup.shown) ? WlrLayer.Overlay : WlrLayer.Top

            anchors {
                bottom: true
                left: true
                right: true
                top: true
            }

            Bar {
                id: bar
                visible: !visualWindow.hasFullscreen
            }

            OSD {
                id: osd
                z: 20
                hasFullscreen: visualWindow.hasFullscreen
            }
            NotificationPopup {
                id: notificationPopup
                z: 20
                hasFullscreen: visualWindow.hasFullscreen
            }

            AnimatedContentLoader {
                id: overviewLoader
                z: 50
                anchors.fill: parent
                shouldBeActive: ShellState.overviewOpen && visualWindow.screen && ShellState.activeScreenName === visualWindow.screen.name
                sourceComponent: Component {
                    WorkspaceOverview {
                        screen: visualWindow.screen
                    }
                }
            }

            // ── Drawers ──────────────────────────────────────────────
            Dashboard {
                id: dashboardDrawer
                screen: visualWindow.screen
                triggerHovered: borderBezels.topHovered
            }
            ControlCenter {
                id: controlCenterDrawer
                screen: visualWindow.screen
                triggerHovered: borderBezels.rightHovered
            }
            SystemDrawer {
                id: systemDrawer
                screen: visualWindow.screen
                triggerHovered: borderBezels.leftHovered
            }

            Loader {
                id: wallpaperOverlayLoader
                anchors.fill: parent
                active: visualWindow.showingWallpaper
                sourceComponent: Component {
                    WallpaperOverlay {}
                }
            }
            // ── Border bezels + hover detection ──
            BorderBezels {
                id: borderBezels
                visible: !visualWindow.hasFullscreen
                bezelSize: rootScope.bezelSize
                topBarHeight: rootScope.topBarHeight
            }

            Connections {
                target: borderBezels
                function onTopHoveredChanged() {
                    if (!visualWindow.screen)
                        return;
                    if (borderBezels.topHovered && !dashboardDrawer.toggleOnHover)
                        return; // dashboard uses toggleOnHover:false, ignore hover-open here
                    if (borderBezels.topHovered && !visualWindow.hasMonitorAbove)
                        ShellState.openDashboardTabs(visualWindow.screen.name);
                }
                // onBottomHoveredChanged — REMOVED (was QuickActions-only).
                function onLeftHoveredChanged() {
                    if (!visualWindow.screen)
                        return;
                    if (borderBezels.leftHovered && systemDrawer.toggleOnHover && !visualWindow.hasMonitorToLeft)
                        ShellState.openSystemDrawer(visualWindow.screen.name);
                }
                function onRightHoveredChanged() {
                    if (!visualWindow.screen)
                        return;
                    if (borderBezels.rightHovered && controlCenterDrawer.toggleOnHover && !visualWindow.hasMonitorToRight)
                        ShellState.openControlCenter(visualWindow.screen.name);
                }
            }

            // ── Mask ──────────────────────────────────────────────
            mask: Region {
                Region {
                    item: bar
                }
                Region {
                    item: dashboardDrawer.panelItem
                }
                Region {
                    item: dashboardDrawer.footerMaskTarget
                }
                Region {
                    item: controlCenterDrawer.panelItem
                }
                Region {
                    item: systemDrawer.panelItem
                }
                Region {
                    item: osd.panelItem
                }
                Region {
                    item: notificationPopup.panelItem
                }
                Region {
                    width: overviewLoader.shouldBeActive ? visualWindow.width : 0
                    height: overviewLoader.shouldBeActive ? visualWindow.height : 0
                }
                Region {
                    item: borderBezels.topBorderItem
                }
                Region {
                    item: borderBezels.bottomBorderItem
                }
                Region {
                    item: borderBezels.leftBorderItem
                }
                Region {
                    item: borderBezels.rightBorderItem
                }
            }
        }

        // ---------------------------------------------------------
        // 3. Reservation windows (bar height + bezel margins)
        // ---------------------------------------------------------
        ExclusionZones {
            screen: rootScope.screen
            barHeight: rootScope.topBarHeight
            bezelSize: rootScope.bezelSize
        }
    }
}
