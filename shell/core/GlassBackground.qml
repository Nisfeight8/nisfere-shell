import QtQuick
import qs.core

Item {
    id: root
    property real bgRadius: Theme.radius
    anchors.fill: parent
    clip: true

    // Base translucent background
    Rectangle {
        anchors.fill: parent
        radius: root.bgRadius
        color: Theme.backgroundAlt
        opacity: 0.65
    }

    // ✅ Native Rectangle gradient 
    Rectangle {
        anchors.fill: parent
        radius: root.bgRadius
        gradient: Gradient {
            GradientStop { position: 0.0;  color: Qt.alpha(Theme.backgroundAlt, 0.2) }
            GradientStop { position: 0.55; color: "transparent" }
            GradientStop { position: 1.0;  color: Qt.alpha(Theme.selected, 0.08) }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: root.bgRadius
        // border.color: Theme.borderColor
        // border.width: Theme.widgetBorderWidth

        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.widgetBorderWidth
            color: "transparent"
            radius: Math.max(0, root.bgRadius - 1)
        }
    }
}