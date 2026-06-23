import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root

    // --- Configuration Properties ---
    property string activeIcon: "󰃠"
    property string mutedIcon: "󰝟"
    property bool isMuteable: false
    property bool isMuted: false

    // The incoming value from your backend service
    property real value: 0.0

    // Dynamic Text: Defaults to percentage, but parent can override it!
    property string valueText: (root.isMuteable && root.isMuted) ? "Mute" : Math.round(internalSlider.value * 100) + "%"

    // --- Signals ---
    signal toggleMuteClicked

    // Fires constantly while dragging (Use for Volume)
    signal liveValueMoved(real newValue)

    // Fires ONLY when the mouse is released (Use for Brightness)
    signal finalValueChanged(real newValue)

    Layout.fillWidth: true
    spacing: 12

    Rectangle {
        border.color: (root.isMuteable && root.isMuted) ? Theme.borderColor : "transparent"
        color: (root.isMuteable && root.isMuted) ? Theme.backgroundAlt : "transparent"
        height: 36
        radius: 18
        width: 36

        Text {
            anchors.centerIn: parent
            color: (root.isMuteable && root.isMuted) ? Theme.foreground : Theme.selected
            font.pixelSize: 18
            opacity: (root.isMuteable && root.isMuted) ? 0.5 : 1.0
            text: root.isMuted ? root.mutedIcon : root.activeIcon
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: root.isMuteable
            hoverEnabled: root.isMuteable

            onClicked: root.toggleMuteClicked()
        }
    }

    ControlSlider {
        id: internalSlider

        Layout.fillWidth: true
        isMuted: root.isMuteable && root.isMuted

        // Two-way visual binding
        value: root.value

        // 1. Emit live changes
        onMoved: {
            root.liveValueMoved(internalSlider.value);
        }

        // 2. Emit the final value when the user lets go
        onPressedChanged: {
            if (!pressed) {
                root.finalValueChanged(internalSlider.value);
            }
        }
    }

    Text {
        Layout.preferredWidth: 35
        color: Theme.foreground
        font.pixelSize: 12
        horizontalAlignment: Text.AlignRight
        opacity: 0.7
        text: root.valueText
    }
}
