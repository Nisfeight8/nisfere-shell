import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.core

BarWidget {
    id: workspacesWidget

    bgColor: "transparent"
    paddingX: 0
    spacing: 14

    Repeater {
        model: Hyprland.workspaces.values

        delegate: WorkspaceButton {
        }
    }
}
