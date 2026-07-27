import QtQuick
import QtQuick.Layouts
import qs.core

// Reusable search bar — fixes a bug present in every hand-rolled search
// input across the shell: the placeholder was conditioned on
// `!text && !activeFocus`, but most of these auto-forceActiveFocus() the
// moment they open (so you can type immediately) — meaning activeFocus
// is true essentially the whole time the field is visible, hiding the
// placeholder almost always regardless of whether there's text. The
// placeholder should depend ONLY on whether the field is empty.
//
// The underlying TextInput is exposed via `input` (for forceActiveFocus,
// reading cursorPosition, etc.), and raw key events are re-emitted via
// `keyPressed` so callers needing custom navigation (arrow keys, Tab,
// Escape — like CentralLauncher's app grid) can still hook in without
// needing to reach into the component's internals.
//
// Usage:
//   SearchBar {
//       placeholderText: "Search apps..."
//       onKeyPressed: (event) => { ... event.accepted = true; ... }
//       onAccepted: doSomething(text)
//   }
Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholderText: "Search..."
    property bool showClearButton: true

    signal accepted
    signal keyPressed(var event)

    height: 40
    radius: Theme.radius
    color: Theme.backgroundAlt
    border.width: 1
    border.color: input.activeFocus ? Theme.selected : Theme.borderColor
    Behavior on border.color {
        AnimColor {
            type: Anim.FastEffects
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 8
        }
        spacing: 8

        LucideIcon {
            icon: "search"
            size: 15
            color: Theme.foreground
            opacity: 0.5
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextInput {
                id: input
                anchors.fill: parent
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 14
                clip: true
                selectByMouse: true
                verticalAlignment: TextInput.AlignVCenter

                Keys.onReturnPressed: root.accepted()
                Keys.onEnterPressed: root.accepted()
                Keys.onPressed: event => {
                    // Return/Enter already fire `accepted` above — don't
                    // ALSO forward them through keyPressed, or a consumer
                    // reacting to both (e.g. CentralLauncher's app grid,
                    // which might treat Enter as "activate selection")
                    // would end up double-triggering off a single keypress.
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        return;
                    root.keyPressed(event);
                }
            }

            // Placeholder — visible whenever empty, regardless of focus.
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.placeholderText
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 14
                opacity: 0.35
                visible: input.text === ""
                elide: Text.ElideRight
                width: parent.width
            }
        }

        IconButton {
            visible: root.showClearButton && input.text !== ""
            icon: "x"
            size: 22
            iconSize: 12
            normalColor: "transparent"
            onTapped: input.text = ""
        }
    }
}
