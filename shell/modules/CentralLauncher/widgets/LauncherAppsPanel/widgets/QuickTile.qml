import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

// Small app tile for the Favorites/Recent/Most Used quick-access rows.
//
// Property is named `modelData` (not `appData`) DELIBERATELY — for
// plain JavaScript array models (like this one gets, built via
// .map()/.filter()), the Repeater's automatic "modelData" context
// injection isn't reliable across all Qt/Quickshell versions the way
// it is for proper model types (e.g. DesktopEntries.applications).
// Declaring `required property var modelData` directly on the
// delegate's root explicitly claims that role by its expected name,
// which works deterministically regardless of model type.
Rectangle {
    id: tile

    required property var modelData
    signal tapped

    readonly property bool isHovered: hover.hovered

    width: 76
    height: 84
    radius: Theme.radius
    color: isHovered ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.12) : "transparent"
    Behavior on color {
        AnimColor {
            type: Anim.FastEffects
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

        Image {
            Layout.alignment: Qt.AlignHCenter
            source: Quickshell.iconPath(tile.modelData.icon)
            sourceSize: Qt.size(36, 36)
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 72
            text: tile.modelData.name
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
            opacity: 0.85
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        onTapped: tile.tapped()
    }
}
