import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.core
import qs.services

// A single notification entry — icon, app name + timestamp, summary +
// body, close button. Subtle hover tint plus a colored accent bar
// (critical notifications get Theme.color1, everything else
// Theme.selected) for at-a-glance priority without needing to read
// any text. Extracted out of Notifications.qml so it's independently
// reusable/testable.
GlassCard {
    id: card

    required property var notif
    property real cardHeight: 85
    property real iconSize: 40
    property real fontSizeTitle: 14
    property real fontSizeBody: 11

    signal closeRequested

    readonly property bool isHovered: cardHover.hovered
    readonly property color accentColor: notif.isCritical ? Theme.color1 : Theme.selected

    height: cardHeight

    // Whole-card hover tint — subtle, spans the full area since hover
    // is a continuous state (matches ControlButton's own convention).
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, card.isHovered ? 0.04 : 0)
        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
    }

    // Priority accent bar — a persistent edge strip reads "this is
    // critical" at a glance even when you're not looking at the icon.
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 8
        width: 3
        radius: 1.5
        color: card.accentColor
        opacity: 0.8
    }

    HoverHandler {
        id: cardHover
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        anchors.leftMargin: 20   // extra room for the accent bar
        spacing: 14

        // App icon / notification icon
        Rectangle {
            Layout.preferredWidth: card.iconSize
            Layout.preferredHeight: card.iconSize
            radius: Theme.radius
            color: Theme.background
            border.width: 1
            border.color: Theme.borderColor
            clip: true   // safety net for anything else that might overflow

            LucideIcon {
                anchors.centerIn: parent
                size: card.iconSize * 0.8
                icon: notif.isCritical ? "alert-triangle" : "bell"
                color: card.accentColor
                visible: !notif.nAppIcon && !notif.nImage
            }

            // Hidden — only used as texture source for OpacityMask below
            Image {
                id: notifImage
                anchors.fill: parent
                anchors.margins: 4
                fillMode: Image.PreserveAspectFit
                source: notif.nAppIcon || notif.nImage || ""
                asynchronous: true
                cache: true
                visible: false
                sourceSize.width: card.iconSize
                sourceSize.height: card.iconSize
            }
            Rectangle {
                id: notifImageMask
                anchors.fill: notifImage
                radius: Theme.radius - 4   // slightly smaller to match the inset margin
                visible: false
            }
            // Rounds the image's corners to match the badge — plain clip:true
            // only clips to the rectangular bounds, not the rounded shape, so
            // the image's own square corners would still poke out past the
            // background's curve without this.
            OpacityMask {
                anchors.fill: notifImage
                source: notifImage
                maskSource: notifImageMask
                visible: notifImage.source !== ""
            }
        }

        // Text content
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: (notif.nAppName || "SYSTEM").toUpperCase()
                    color: card.accentColor
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: card.fontSizeTitle
                    opacity: 0.8
                }
                Item {
                    Layout.fillWidth: true
                }
                Text {
                    text: notif.timeReceived || ""
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: card.fontSizeTitle
                    opacity: 0.4
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: notif.nSummary || ""
                color: Theme.foreground
                elide: Text.ElideRight
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: card.fontSizeTitle + 2
            }
            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: notif.nBody || ""
                color: Theme.foreground
                elide: Text.ElideRight
                font.family: Theme.fontName
                font.pixelSize: card.fontSizeBody
                maximumLineCount: 1
                opacity: 0.6
            }
        }

        // Close button — full opacity only on hover, reducing visual
        // noise when you're just scanning the list rather than
        // dismissing something.
        IconButton {
            icon: "x"
            size: 28
            iconSize: 14
            normalColor: Theme.backgroundAlt
            radius: Theme.radius
            hoverColor: Theme.color1
            opacity: card.isHovered ? 1 : 0.35
            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }
            onTapped: card.closeRequested()
        }
    }
}
