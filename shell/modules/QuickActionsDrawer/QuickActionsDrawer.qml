import QtQuick
import Quickshell.Io
import qs.core
import qs.services
import "widgets/ThemeManager"
import "widgets/WallpaperManager"
import "widgets"

BaseDrawer {
    id: root

    edge: Qt.BottomEdge
    edgeMargin: Theme.panelBorderSize
    minPanelWidth: Screen.width * 0.20
    toggleOnHover: true

    // Simplified: `opened` tracks only the toggle state now, since
    // nested panels always close the WHOLE drawer directly (no more
    // "stay open while quickAction is set" special case needed).
    opened: ShellState.quickActionsOpened

    onCloseRequest: {
        ShellState.quickActionsOpened = false;
        // Delay the reset until the close-slide animation has finished
        // (BaseDrawer's closeOffsetAnim — Anim.FastSpatial, 350ms).
        // Resetting quickAction immediately would swap the still-visible
        // content back to the bar WHILE the drawer is sliding away,
        // causing a visible flash of the bar right before it disappears.
        resetQuickActionTimer.restart();
    }
    onOpenRequest: {
        ShellState.quickActionsOpened = true;
        // Cancel any pending reset from a previous close — if the drawer
        // is reopened quickly (e.g. a brief hover blip), the last tab
        // should still be showing, not snap back to the bar.
        resetQuickActionTimer.stop();
    }

    Timer {
        id: resetQuickActionTimer
        interval: 100
        onTriggered: ShellState.quickAction = ""
    }
    onToggleRequest: {
        if (ShellState.quickActionsOpened) {
            ShellState.quickActionsOpened = false;
            resetQuickActionTimer.restart();
        } else {
            ShellState.quickActionsOpened = true;
            resetQuickActionTimer.stop();
        }
    }

    contentComponent: Component {
        Item {
            id: rootContent

            property real _lastHeight: 0
            property real _lastWidth: 0
            implicitHeight: _lastHeight
            implicitWidth: _lastWidth

            function _syncSize() {
                const item = pageLoader.item;
                if (!item)
                    return;
                if (item.implicitWidth > 0)
                    _lastWidth = item.implicitWidth;
                if (item.implicitHeight > 0)
                    _lastHeight = item.implicitHeight;
            }

            Component.onCompleted: forceActiveFocus()

            Connections {
                target: pageLoader.item
                function onImplicitHeightChanged() {
                    rootContent._syncSize();
                }
                function onImplicitWidthChanged() {
                    rootContent._syncSize();
                }
            }

            Keys.onEscapePressed: root.closeRequest()

            // ── Page components ─────────────────────────────────────
            Component {
                id: barComp
                QuickActionsBar {
                    onActionRequested: action => {
                        // colorpicker has no panel — run immediately
                        if (action === "colorpicker") {
                            root._runColorPicker();
                            return;
                        }
                        ShellState.quickAction = action;
                    }
                }
            }

            Component {
                id: screenshotComp
                ScreenshotPanel {}
            }
            Component {
                id: recordComp
                RecordPanel {}
            }
            Component {
                id: wallpaperComp
                WallpaperManager {}
            }
            Component {
                id: colorsComp
                ThemeManager {}
            }
            Component {
                id: clipboardComp
                ClipboardPanel {}
            }

            // ── Page content — no back header, no manual navigation.
            // Nested panels close the WHOLE drawer directly when done
            // (see ScreenshotPanel/RecordPanel), so there is no
            // "return to bar" transition to handle or glitch on.
            AnimLoader {
                id: pageLoader
                anchors.fill: parent

                sourceComp: {
                    switch (ShellState.quickAction) {
                    case "screenshot":
                        return screenshotComp;
                    case "recorder":
                        return recordComp;
                    case "wallpaper":
                        return wallpaperComp;
                    case "colors":
                        return colorsComp;
                    case "clipboard":
                        return clipboardComp;
                    default:
                        return barComp;
                    }
                }

                onItemChanged: rootContent._syncSize()
            }
        }
    }

    // ── Color picker ────────────────────────────────────────────
    // We capture hyprpicker's stdout ourselves and copy it via wl-copy,
    // rather than relying on hyprpicker's built-in -a/--autocopy flag —
    // that depends on wl-clipboard being present and has been flaky on
    // some versions. Doing it explicitly guarantees the copy happens,
    // and lets us show a notification with the picked color.
    property Process _pickerProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let hex = text.trim();
                if (hex) {
                    root._copyProc.command = ["wl-copy", hex];
                    root._copyProc.running = true;
                    InternalNotificationService.send("Color picked", hex, "color-picker");
                } else {
                    InternalNotificationService.send("Color picker cancelled", "", "color-picker", "low");
                }
            }
        }
    }
    property Process _copyProc: Process {
        running: false
    }

    function _runColorPicker() {
        _pickerProc.command = ["hyprpicker", "-f", "hex"];
        _pickerProc.running = true;
    }
}
