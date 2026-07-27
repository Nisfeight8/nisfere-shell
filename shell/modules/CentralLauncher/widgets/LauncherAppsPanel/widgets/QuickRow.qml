import QtQuick
import QtQuick.Layouts
import qs.core

// Horizontal quick-access row (Favorites/Recent/Most Used). Takes an
// already-resolved list of DesktopEntry objects — resolution (name ->
// full app data) happens in the parent, keeping this component simple.
Item {
    id: quickRow

    property string title: ""
    property var appsList: []   // resolved DesktopEntry objects
    signal appTapped(var appData)

    visible: appsList.length > 0
    implicitHeight: visible ? col.implicitHeight : 0

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 4

        Text {
            text: quickRow.title
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 11
            font.bold: true
            opacity: 0.5
        }

        Flow {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: quickRow.appsList

                delegate: QuickTile {
                    onTapped: quickRow.appTapped(modelData)
                }
            }
        }
    }
}
