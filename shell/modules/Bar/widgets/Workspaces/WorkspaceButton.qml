import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: wsItem

    required property var modelData   // HyprlandWorkspace

    // Native `focused` property — correctly accounts for multi-monitor
    // (active on its monitor AND that monitor is focused), instead of
    // manually comparing IDs against Hyprland.focusedWorkspace.
    readonly property bool isFocused: modelData.focused

    // HyprlandWorkspace already exposes its own toplevels directly —
    // no need to manually filter Hyprland.toplevels.values by workspace id.
    readonly property var myWindows: modelData.toplevels.values
    readonly property int windowsCount: myWindows.length

    implicitWidth: content.implicitWidth + 16
    implicitHeight: widgetHeight

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: wsItem.isFocused ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15) : hover.hovered ? Theme.backgroundAlt : "transparent"
        border.width: wsItem.isFocused ? 1 : 0
        border.color: Theme.selected
    }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 6

        // ── Workspace indicator glyph ─────────────────────────────
        Text {
            color: wsItem.isFocused ? Theme.selected : Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: wsItem.isFocused ? 24 : 16
            text: {
                if (wsItem.isFocused)
                    return "󰮯";
                if (wsItem.windowsCount > 0)
                    return "󰊠";
                return "";
            }
            Behavior on font.pixelSize {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutBack
                }
            }
        }

        // ── App icons — real icons, always visible ────────────────
        Row {
            visible: wsItem.windowsCount > 0
            spacing: 5

            Repeater {
                model: wsItem.myWindows   // HyprlandToplevel[]

                delegate: Text {
                    id: iconWrap
                    required property var modelData   // HyprlandToplevel

                    // Prefer the Wayland toplevel's appId (standard
                    // protocol field, populated as soon as the window's
                    // address is reported — fast). Fall back to
                    // Hyprland's own IPC-derived class field.
                    readonly property string appClass: {
                        if (modelData.wayland && modelData.wayland.appId)
                            return modelData.wayland.appId;
                        if (modelData.lastIpcObject && modelData.lastIpcObject.class)
                            return modelData.lastIpcObject.class;
                        return "";
                    }

                    color: Theme.selected
                    font.family: Theme.fontName
                    font.pixelSize: wsItem.isFocused ? 16 : 14
                    text: Icons.getAppIcon(appClass)
                }
            }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        // HyprlandWorkspace.activate() handles dispatch internally —
        // no manual "workspace " + name string building, so there's
        // nothing that can break on an undefined name.
        onTapped: wsItem.modelData.activate()
    }
}
