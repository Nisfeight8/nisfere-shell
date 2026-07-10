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
    readonly property real iconSize: Math.max(32, 40 * baseScale)

    anchors.fill: parent
    implicitWidth: parent.width
    implicitHeight: parent.height

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(15, 25 * root.baseScale)
        spacing: Math.max(10, 15 * root.baseScale)

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 45

            RowLayout {
                spacing: 10

                Text {
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(18, 22 * root.baseScale)
                    text: "Notifications"
                }
                Rectangle {
                    color: Theme.selected
                    height: 22
                    opacity: 0.9
                    radius: 11
                    visible: NotificationService.notifications.length > 0
                    width: Math.max(22, notifCountText.implicitWidth + 12)

                    Text {
                        id: notifCountText

                        anchors.centerIn: parent
                        color: Theme.background
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 14
                        text: NotificationService.notifications.length
                    }
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Rectangle {
                id: dndBtn

                border.color: Theme.borderColor
                border.width: Theme.widgetBorderWidth
                color: NotificationService.dndEnabled ? Theme.selected : Theme.backgroundAlt
                height: 40
                radius: Theme.radius
                width: 40

                LucideIcon {
                    anchors.centerIn: parent
                    size: 16
                    color: NotificationService.dndEnabled ? Theme.background : Theme.foreground
                    icon: Icons.getDndIcon(NotificationService.dndEnabled)
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: NotificationService.toggleDnd()
                }
            }
            Rectangle {
                id: clearBtn

                border.color: Theme.borderColor
                border.width: Theme.widgetBorderWidth
                color: Theme.backgroundAlt
                height: 40
                radius: Theme.radius
                visible: NotificationService.notifications.length > 0
                width: 40

                LucideIcon {
                    anchors.centerIn: parent
                    size: 16
                    color: Theme.color1
                    icon: "trash"
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: NotificationService.clearAll()
                }
            }
        }
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true

            ColumnLayout {
                anchors.centerIn: parent
                opacity: 0.4
                spacing: 12
                visible: NotificationService.notifications.length === 0

                LucideIcon {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.foreground
                    size: 54
                    icon: Icons.getDndIcon(NotificationService.dndEnabled)
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    text: NotificationService.dndEnabled ? "Do Not Disturb is on" : "No new notifications"
                }
            }
            ListView {
                id: notifListView

                anchors.fill: parent
                clip: true
                model: NotificationService.notifications
                spacing: 10
                visible: NotificationService.notifications.length > 0

                add: Transition {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutQuad
                        from: 0
                        properties: "opacity,scale"
                        to: 1
                    }
                }
                delegate: GlassCard {
                    id: card

                    property var notif: modelData

                    height: root.cardHeight
                    width: notifListView.width

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 14

                        Rectangle {
                            Layout.preferredHeight: root.iconSize
                            Layout.preferredWidth: root.iconSize
                            border.color: Theme.borderColor
                            border.width: 1
                            color: Theme.background
                            radius: 8

                            LucideIcon {
                                anchors.centerIn: parent
                                size: root.iconSize * 0.8
                                color: notif.isCritical ? Theme.color1 : Theme.selected
                                icon: notif.isCritical ? "alert-triangle" : "bell"
                                visible: !notif.nAppIcon && !notif.nImage
                            }
                            Image {
                                anchors.fill: parent
                                anchors.margins: 4
                                fillMode: Image.PreserveAspectFit
                                source: notif.nAppIcon ? notif.nAppIcon : (notif.nImage ? notif.nImage : "")
                                visible: source !== ""
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    color: notif.isCritical ? Theme.color1 : Theme.selected
                                    font.bold: true
                                    font.family: Theme.fontName
                                    font.pixelSize: root.fontSizeTitle
                                    opacity: 0.8
                                    text: (notif.nAppName || "SYSTEM").toUpperCase()
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                Text {
                                    color: Theme.foreground
                                    font.family: Theme.fontName
                                    font.pixelSize: root.fontSizeTitle
                                    opacity: 0.4
                                    text: notif.timeReceived || ""
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0   // ✅ defensive — elide δεν επηρεάζει implicit width
                                color: Theme.foreground
                                elide: Text.ElideRight
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: root.fontSizeTitle + 2
                                text: notif.nSummary || ""
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0   // ✅ defensive
                                color: Theme.foreground
                                elide: Text.ElideRight
                                font.family: Theme.fontName
                                font.pixelSize: root.fontSizeBody
                                maximumLineCount: 1
                                opacity: 0.6
                                text: notif.nBody || ""
                            }
                        }
                        Rectangle {
                            id: closeBtn

                            Layout.preferredHeight: 28
                            Layout.preferredWidth: 28
                            color: closeMouse.containsMouse ? Theme.color1 : "transparent"
                            radius: 6

                            Text {
                                anchors.centerIn: parent
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 12
                                opacity: closeMouse.containsMouse ? 1 : 0.3
                                text: "󰅖"
                            }
                            MouseArea {
                                id: closeMouse

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: {
                                    NotificationService.close(index);
                                }
                            }
                        }
                    }
                }
                displaced: Transition {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutBack
                        properties: "y"
                    }
                }
                remove: Transition {
                    NumberAnimation {
                        duration: 200
                        properties: "opacity,scale"
                        to: 0
                    }
                }
            }
        }
    }
}
