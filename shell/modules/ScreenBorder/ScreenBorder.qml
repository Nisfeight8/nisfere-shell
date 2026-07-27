import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.Bar
import qs.modules.Dashboard
import qs.modules.ControlCenter
import qs.modules.SystemDrawer
import qs.modules.QuickActions
import qs.modules.CentralLauncher
import qs.modules.Osd
import qs.modules.NotificationPopup
import qs.modules.WorkspaceOverview

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

        property real bezelSize: Theme.panelBorderSize
        readonly property real topBarHeight: Theme.barHeight

        // ---------------------------------------------------------
        // 1. Ο VISUAL WINDOW (μπάρα, drawers, launcher, overview, bezels)
        // ---------------------------------------------------------
        PanelWindow {
            id: visualWindow
            screen: rootScope.screen

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            // Was just the 4 booleans OR'd together — none of them are
            // screen-aware on their own (appLauncherOpened/overviewOpen
            // have no per-screen concept at all; dashboardOpened's own
            // per-screen visibility is handled separately by
            // BaseDrawer, but doesn't stop THIS window from thinking
            // "something is open" just because a DIFFERENT screen's
            // dashboard is). Added the same activeScreenName check so
            // only the screen that's actually showing something grabs
            // exclusive keyboard focus / raises its layer.
            readonly property bool isAnyUIOpen: ShellState.activeScreenName === screen.name && (ShellState.appLauncherOpened || ShellState.quickActionsOpened || ShellState.overviewOpen || (ShellState.dashboardOpened && ShellState.currentDashboardTab == 4 && ShellState.currentProductivityTab === 0))

            // ── Fullscreen detection ──────────────────────────────────
            readonly property var _monitorData: HyprlandData.monitors.find(m => m.name === screen.name)
            readonly property int activeWorkspaceId: _monitorData?.activeWorkspace?.id ?? -1
            readonly property bool hasFullscreen: HyprlandData.windowList.some(w => (w.workspace?.id ?? -1) === activeWorkspaceId && (w.fullscreen ?? 0) > 0)

            // ── Adjacent-monitor detection ─────────────────────────────
            // Moving the cursor between two side-by-side monitors passes
            // straight through the shared boundary — e.g. eDP-1 at 0x0
            // and HDMI-A-1 at 1920x0 means crossing from one to the
            // other goes right through eDP-1's right edge into
            // HDMI-A-1's left edge. Any hover-triggered drawer sitting
            // on that shared edge (SystemDrawer, on the left) would
            // pop open just from passing through, not a deliberate
            // hover. Only suppress hover-OPEN on edges that actually
            // border another monitor — outer/physical edges of the
            // whole desktop still work normally.
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
            readonly property bool hasMonitorToLeft: _monitorData ? HyprlandData.monitors.some(m => m.name !== _monitorData.name && Math.abs((m.x + m.width) - _monitorData.x) < 2 && _yOverlaps(m)) : false
            readonly property bool hasMonitorToRight: _monitorData ? HyprlandData.monitors.some(m => m.name !== _monitorData.name && Math.abs(m.x - (_monitorData.x + _monitorData.width)) < 2 && _yOverlaps(m)) : false
            readonly property bool hasMonitorAbove: _monitorData ? HyprlandData.monitors.some(m => m.name !== _monitorData.name && Math.abs((m.y + m.height) - _monitorData.y) < 2 && _xOverlaps(m)) : false
            readonly property bool hasMonitorBelow: _monitorData ? HyprlandData.monitors.some(m => m.name !== _monitorData.name && Math.abs(m.y - (_monitorData.y + _monitorData.height)) < 2 && _xOverlaps(m)) : false
            Component.onCompleted: {
                console.log(screen.name)
            }
            WlrLayershell.keyboardFocus: isAnyUIOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
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

            // OSD/NotificationPopup — both are BaseDrawer instances
            // (cornerMode bottom-right). Visibility itself is NOT gated on
            // hasFullscreen (a volume change or incoming notification
            // should still show even in a fullscreen app) — only their
            // screenOffset changes (no bar to avoid when fullscreen, since
            // Bar/BorderBezels are hidden then anyway).
            // NOTE: these two are NOT screen-gated (no `screen:` passed) —
            // they'll show on every screen's instance right now. Whether
            // that's wanted (e.g. volume OSD showing wherever you are)
            // or should follow activeScreenName too is worth deciding
            // once you've tested with a second monitor.
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

            // Overview's AnimatedContentLoader lives here (below).
            // Reasoning for staying a plain-visibility PanelWindow /
            // AnimatedContentLoader rather than needing any extra
            // unload-delay: Overview's own window already hides itself
            // instantly via `visible: ShellState.overviewOpen`, so there's
            // nothing left rendering/animating by the time a delay would
            // matter (unlike CentralLauncher, which stays mounted inside
            // an already-visible host window).

            // Both were `shouldBeActive: ShellState.appLauncherOpened` /
            // `ShellState.overviewOpen` alone — neither of these loaders
            // has anything like BaseDrawer's screenName/openedRequest
            // gating, so without the activeScreenName check added here,
            // opening the launcher/overview on ONE screen would activate
            // it on EVERY screen simultaneously.
            AnimatedContentLoader {
                id: appLauncherLoader
                z: 50
                anchors.fill: parent
                shouldBeActive: ShellState.appLauncherOpened && ShellState.activeScreenName === visualWindow.screen.name
                sourceComponent: Component {
                    CentralLauncher {}
                }
            }
            AnimatedContentLoader {
                id: overviewLoader
                z: 50
                anchors.fill: parent
                shouldBeActive: ShellState.overviewOpen && ShellState.activeScreenName === visualWindow.screen.name
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

            QuickActions {
                id: quickActionsDrawer
                screen: visualWindow.screen
                triggerHovered: borderBezels.bottomHovered
            }

            // ── Border bezels + hover detection (decoupled component) ──
            BorderBezels {
                id: borderBezels
                visible: !visualWindow.hasFullscreen
                bezelSize: rootScope.bezelSize
                topBarHeight: rootScope.topBarHeight
            }

            // ── Hover -> open wiring (kept HERE, not inside BorderBezels,
            // so BorderBezels stays reusable/decoupled from drawer logic).
            // Goes through ShellState's own open methods, which also
            // record activeScreenName — this is what makes the whole
            // per-screen gating above actually work correctly: whichever
            // screen's bezel you hover sets itself as the active one. ──
            Connections {
                target: borderBezels
                function onTopHoveredChanged() {
                    if (borderBezels.topHovered && !dashboardDrawer.toggleOnHover)
                        return; // dashboard uses toggleOnHover:false, ignore hover-open here
                    if (borderBezels.topHovered && !visualWindow.hasMonitorAbove)
                        ShellState.openDashboard(visualWindow.screen.name);
                }
                function onBottomHoveredChanged() {
                    if (borderBezels.bottomHovered && quickActionsDrawer.toggleOnHover && !visualWindow.hasMonitorBelow)
                        ShellState.openQuickActions(visualWindow.screen.name);
                }
                function onLeftHoveredChanged() {
                    if (borderBezels.leftHovered && systemDrawer.toggleOnHover && !visualWindow.hasMonitorToLeft)
                        ShellState.openSystemDrawer(visualWindow.screen.name);
                }
                function onRightHoveredChanged() {
                    if (borderBezels.rightHovered && controlCenterDrawer.toggleOnHover && !visualWindow.hasMonitorToRight)
                        ShellState.openControlCenter(visualWindow.screen.name);
                }
            }

            // ── Mask: bar + whichever drawer/loader is currently relevant,
            // everything else click-through ──────────────────────────────
            mask: Region {
                Region {
                    item: bar
                }
                Region {
                    item: dashboardDrawer.panelItem
                }
                Region {
                    item: controlCenterDrawer.panelItem
                }
                Region {
                    item: systemDrawer.panelItem
                }
                Region {
                    item: quickActionsDrawer.panelItem
                }
                Region {
                    item: osd.panelItem
                }
                Region {
                    item: notificationPopup.panelItem
                }
                Region {
                    width: appLauncherLoader.shouldBeActive ? visualWindow.width : 0
                    height: appLauncherLoader.shouldBeActive ? visualWindow.height : 0
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
        // 2. Reservation windows (bar height + bezel margins)
        // ---------------------------------------------------------
        ExclusionZones {
            screen: rootScope.screen
            barHeight: rootScope.topBarHeight
            bezelSize: rootScope.bezelSize
        }
    }
}
