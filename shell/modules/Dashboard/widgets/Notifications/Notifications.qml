import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    property real safeWidth: parent.width
    property real safeHeight: parent.height

    readonly property real baseScale: Math.min(root.safeWidth / 550, root.safeHeight / 600)
    readonly property real cardHeight: Math.max(75, 85 * baseScale)
    readonly property real fontSizeBody: Math.max(11, 14 * baseScale)
    readonly property real fontSizeTitle: Math.max(12, 14 * baseScale)
    readonly property real iconSize: Math.max(50, 40 * baseScale)

    anchors.fill: parent
    // NOTE: unlike Media/Weather, this tab is deliberately
    // responsive-scaling (baseScale above stretches icon/font/card
    // sizes to whatever actual space it's given) rather than having a
    // fixed natural content size — so implicitWidth/Height staying
    // tied to parent's actual size may be intentional here rather
    // than the same bug as Media/Weather. Left as-is pending your call
    // on whether this tab should also drive its own custom size.
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
                hoverColor: Theme.selected
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
                    Anim {
                        properties: "opacity,scale"
                        from: 0
                        to: 1
                        type: Anim.DefaultEffects
                    }
                }
                // Deliberately NOT using Anim here — same reasoning as
                // NavTabs/SideMenu: Easing.OutBack's overshoot has no
                // equivalent among our M3 bezier curves, and the little
                // "settle" bounce as other notifications reflow after
                // one is dismissed is a nice, distinctive touch worth
                // keeping raw.
                displaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: 250
                        easing.type: Easing.OutBack
                    }
                }
                remove: Transition {
                    Anim {
                        properties: "opacity,scale"
                        to: 0
                        type: Anim.DefaultEffects
                    }
                }

                delegate: NotificationCard {
                    // 1. Ζητάμε ρητά από το Qt 6 να μας "ταΐσει" αυτές τις μεταβλητές
                    required property var modelData
                    required property int index

                    // 2. Πλέον το modelData και το index υπάρχουν και δουλεύουν κανονικά!
                    width: notifListView.width
                    notif: modelData

                    cardHeight: root.cardHeight
                    iconSize: root.iconSize
                    fontSizeTitle: root.fontSizeTitle
                    fontSizeBody: root.fontSizeBody
                    onCloseRequested: NotificationService.close(index)
                }
            }
        }
    }
}
