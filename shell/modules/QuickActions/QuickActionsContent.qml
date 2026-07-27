import QtQuick
import qs.core
import qs.services

import "widgets"

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

    Keys.onEscapePressed: {
        ShellState.quickActionsOpened = false;
    }

    // ── Page components ─────────────────────────────────────
    Component {
        id: barComp
        QuickActionsBar {
            onActionRequested: action => {
                if (action === "colorpicker") {
                    // 1. Κλείνουμε το drawer αμέσως! (Απελευθερώνει το focus)
                    ShellState.quickActionsOpened = false;

                    // 2. Αντί να τρέξουμε το hyprpicker αμέσως, ξεκινάμε το timer
                    pickerDelayTimer.restart();
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
        WallpapersPanel {}
    }
    Component {
        id: colorsComp
        ThemeQuickPanel {}
    }
    Component {
        id: clipboardComp
        ClipboardPanel {}
    }

    // Was duplicated (an identically-named, ALSO broken Timer used to
    // live inside barComp's own QuickActionsBar block, calling
    // `root._runColorPicker()` — unreachable across the file boundary
    // from QuickActions.qml). Consolidated to this one, now correctly
    // calling the ColorPickerService singleton instead of anything
    // file-scoped.
    Timer {
        id: pickerDelayTimer
        interval: 200
        onTriggered: ColorPickerService.run()
    }

    // ── Page content — no back header, no manual navigation.
    // Nested panels close the WHOLE drawer directly when done
    // (see ScreenshotPanel/RecordPanel), so there is no
    // "return to bar" transition to handle or glitch on.
    AnimLoader {
        id: pageLoader
        anchors.fill: parent
        focus: true
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
