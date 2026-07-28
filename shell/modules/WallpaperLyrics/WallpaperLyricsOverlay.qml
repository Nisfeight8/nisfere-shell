import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

// Sits between the real wallpaper and normal windows (WlrLayer.Bottom)
// — doesn't touch the actual wallpaper-setting mechanism (wallust/
// hyprpaper) at all, just an extra transparent layer on top of it.
// Visible only when: Spotify is playing AND this monitor's active
// workspace has no windows on it (nothing "focused").
PanelWindow {
    id: root

    property var screen: null
    property var monitorData: null   // passed in from ScreenBorder.qml, which already computes this — avoids a second HyprlandData.monitors.find() for the same thing

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    readonly property int _activeWorkspaceId: monitorData?.activeWorkspace?.id ?? -1
    readonly property bool _isIdle: _activeWorkspaceId >= 0 && !HyprlandData.windowList.some(w => (w.workspace?.id ?? -1) === _activeWorkspaceId)
    readonly property bool shouldShow: MediaService.hasPlayer && MediaService.isPlaying && (MediaService.active?.identity.toUpperCase() ?? "") === "SPOTIFY"
   
    visible: shouldShow

    WallpaperLyrics {
        anchors.fill: parent
    }
}
