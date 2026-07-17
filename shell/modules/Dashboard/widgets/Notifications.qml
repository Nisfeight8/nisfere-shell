import QtQuick
import QtQuick.Layouts

import qs.core
import qs.services

Item {
    id: root

    // ✅ Guard κατά του transient zero-size, ίδιο pattern με Media.qml
    property real safeWidth: parent.width
    property real safeHeight: parent.height

    readonly property real baseScale: Math.min(root.safeWidth / 550, root.safeHeight / 600)
    readonly property real cardHeight: Math.max(75, 85 * baseScale)
    readonly property real fontSizeBody: Math.max(11, 14 * baseScale)
    readonly property real fontSizeTitle: Math.max(12, 14 * baseScale)
    readonly property real iconSize: Math.max(50, 40 * baseScale)

    anchors.fill: parent
    implicitWidth: parent.width
    implicitHeight: parent.height

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(15, 25 * root.baseScale)
        spacing: Math.max(10, 15 * root.baseScale)

        // ── Header ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 45

            RowLayout {
                spacing: 10

                Text {
                    text: "Notifications"
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(18, 22 * root.baseScale)
                }
                Rectangle {
                    color: Theme.selected
                    height: 22
                    opacity: 0.9
                    radius: Theme.radius
                    visible: NotificationService.notifications.length > 0
                    width: Math.max(22, notifCountText.implicitWidth + 12)

                    Text {
                        id: notifCountText
                        anchors.centerIn: parent
                        text: NotificationService.notifications.length
                        color: Theme.background
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 14
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // ── DND toggle ────────────────────────────────────────
            IconButton {
                icon: Icons.getDndIcon(NotificationService.dndEnabled)
                size: 40
                normalColor: Theme.backgroundAlt
                // hoverColor: Theme.selected
                isActive: NotificationService.dndEnabled
                activeSolid: true
                dimWhenIdle: false
                onTapped: NotificationService.toggleDnd()
            }

            // ── Clear all ─────────────────────────────────────────
            IconButton {
                icon: "trash"
                size: 40
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.color1
                // alwaysBorder: true
                fixedIconColor: Theme.color1
                dimWhenIdle: false
                visible: NotificationService.notifications.length > 0
                onTapped: NotificationService.clearAll()
            }
        }

        // ── Content ───────────────────────────────────────────────
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                opacity: 0.4
                spacing: 12
                visible: NotificationService.notifications.length === 0

                LucideIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: Icons.getDndIcon(NotificationService.dndEnabled)
                    size: 54
                    color: Theme.foreground
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: NotificationService.dndEnabled ? "Do Not Disturb is on" : "No new notifications"
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 14
                }
            }

            // Notification list
            ListView {
                id: notifListView
                anchors.fill: parent
                clip: true
                spacing: 10
                model: NotificationService.notifications
                visible: NotificationService.notifications.length > 0

                add: Transition {
                    NumberAnimation {
                        properties: "opacity,scale"
                        from: 0
                        to: 1
                        duration: 250
                        easing.type: Easing.OutQuad
                    }
                }
                displaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: 250
                        easing.type: Easing.OutBack
                    }
                }
                remove: Transition {
                    NumberAnimation {
                        properties: "opacity,scale"
                        to: 0
                        duration: 200
                    }
                }

                delegate: GlassCard {
                    id: card
                    property var notif: modelData
                    width: notifListView.width
                    height: root.cardHeight

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 14

                        // App icon / notification icon
                        Rectangle {
                            Layout.preferredWidth: root.iconSize
                            Layout.preferredHeight: root.iconSize
                            radius: Theme.radius
                            color: Theme.background
                            border.width: 1
                            border.color: Theme.borderColor

                            LucideIcon {
                                anchors.centerIn: parent
                                size: root.iconSize * 0.8
                                icon: notif.isCritical ? "alert-triangle" : "bell"
                                color: notif.isCritical ? Theme.color1 : Theme.selected
                                visible: !notif.nAppIcon && !notif.nImage
                            }
                            Image {
                                anchors.fill: parent
                                anchors.margins: 4
                                fillMode: Image.PreserveAspectFit
                                source: notif.nAppIcon || notif.nImage || ""
                                visible: source !== ""
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
                                    color: notif.isCritical ? Theme.color1 : Theme.selected
                                    font.bold: true
                                    font.family: Theme.fontName
                                    font.pixelSize: root.fontSizeTitle
                                    opacity: 0.8
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: notif.timeReceived || ""
                                    color: Theme.foreground
                                    font.family: Theme.fontName
                                    font.pixelSize: root.fontSizeTitle
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
                                font.pixelSize: root.fontSizeTitle + 2
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                text: notif.nBody || ""
                                color: Theme.foreground
                                elide: Text.ElideRight
                                font.family: Theme.fontName
                                font.pixelSize: root.fontSizeBody
                                maximumLineCount: 1
                                opacity: 0.6
                            }
                        }

                        // Close button — hover-solid, icon fixed to foreground
                        IconButton {
                            icon: "x"
                            size: 28
                            iconSize: 14
                            normalColor: Theme.backgroundAlt
                            activeSolid: true
                            radius: Theme.radius
                            hoverColor: Theme.color1
                            onTapped: NotificationService.close(index)
                        }
                    }
                }
            }
        }
    }
}
