import QtQuick
import Quickshell.Hyprland
import qs.core

BarWidget {
    id: workspacesWidget
    useGradient: true
    // bgColor: "transparent"
    paddingX: 0
    spacing: 6

    Repeater {
        model: Hyprland.workspaces.values
        delegate: WorkspaceButton {}
    }
}
