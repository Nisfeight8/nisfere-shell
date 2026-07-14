import QtQuick
import QtQuick.Layouts
import qs.core

// Vertical sidebar tab list — same API as NavTabs (tabModel/currentIndex/
// tabClicked), so the two are interchangeable at the call site, but with
// a visual treatment suited to a left sidebar rather than a top tab-strip:
// left accent bar + background tint on the active row, instead of an
// underline indicator.
ColumnLayout {
    id: root
    property var tabModel: []
    property int currentIndex: 0
    // Layout.preferredWidth: parent.width * 0.4
    signal tabClicked(int tabIndex)

    spacing: 4

    Repeater {
        model: root.tabModel

        delegate: Rectangle {
            property bool isHovered: tabMouse.containsMouse
            property bool isSelected: root.currentIndex === index

            Layout.fillWidth: true
            implicitHeight: 40
            radius: 8
            color: isSelected
                ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.12)
                : isHovered ? Theme.backgroundAlt : "transparent"

            Behavior on color { AnimColor { type: Anim.FastEffects } }

            // Left accent bar — replaces the underline for vertical layout
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: 3
                radius: 1.5
                color: Theme.selected
                opacity: isSelected ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 10 }
                spacing: 10

                LucideIcon {
                    icon: modelData.icon
                    size: 16
                    color: isSelected ? Theme.selected : Theme.foreground
                    opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.5)
                    Behavior on color   { AnimColor { type: Anim.FastEffects } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Text {
                    Layout.fillWidth: true
                    text: modelData.title
                    color: isSelected ? Theme.selected : Theme.foreground
                    font.bold: isSelected
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    opacity: isSelected ? 1.0 : (isHovered ? 0.85 : 0.55)
                    Behavior on color   { AnimColor { type: Anim.FastEffects } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }

            MouseArea {
                id: tabMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.tabClicked(index)
            }
        }
    }

    // Pushes tabs to the top if the sidebar column has extra height
    Item { Layout.fillHeight: true }
}
