import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.core

Item {
    id: wsItem

    readonly property bool isFocused: Hyprland.focusedWorkspace != null && Hyprland.focusedWorkspace.id === modelData.id
    required property var modelData
    property var myWindows: Hyprland.toplevels.values.filter(w => {
        return w.workspace && w.workspace.id === wsItem.modelData.id;
    })
    readonly property var windowsCount: myWindows.length

    height: 24
    width: 24

    Text {
        id: wsText

        anchors.centerIn: parent
        color: isFocused ? Theme.selected : Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: isFocused ? 24 : 16
        text: {
            if (isFocused)
                return "󰮯";

            if (windowsCount > 0)
                return "󰊠";

            return "";
        }

        Behavior on font.pixelSize {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutBack
            }
        }
    }
    MouseArea {
        id: wsMouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: Hyprland.dispatch("workspace " + modelData.name)
    }
    BarPopup {
        id: previewPopup

        showPopup: wsMouseArea.containsMouse
        targetItem: wsItem

        ColumnLayout {
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.selected
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 14
                text: "Workspace " + (modelData.name !== undefined ? modelData.name : "?")
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12
                opacity: 0.8
                text: windowsCount === 1 ? "1 Window" : windowsCount + " Windows"
            }
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                spacing: 8

                Repeater {
                    model: wsItem.myWindows

                    delegate: Text {
                        required property var modelData

                        color: Theme.selected
                        font.family: Theme.fontName
                        font.pixelSize: 16
                        text: Icons.getAppIcon(modelData.lastIpcObject ? modelData.lastIpcObject.class : "")
                    }
                }
            }
        }
    }
}
