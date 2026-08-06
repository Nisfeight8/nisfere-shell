import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    // Fixed — NOT derived from this tab's own width/height. That was
    // the actual bug: tabsLoader (which loads this tab) has no
    // Layout.fillHeight, so it sizes itself from THIS item's own
    // implicitHeight. Binding baseScale to root.height while also
    // computing implicitHeight FROM baseScale is self-referential —
    // and when implicitHeight briefly had no value at all, root's
    // real height collapsed toward 0 (the header RowLayout's
    // Layout.fillHeight ate all the space instead), which fed back
    // into baseScale, which shrunk everything further. A fixed
    // constant breaks that loop entirely. If you want this to vary by
    // monitor, QtQuick's built-in `Screen.width`/`Screen.height`
    // attached property is the safe way — it reads the physical
    // monitor, not this component's own live layout size — happy to
    // wire that in if you want it; left as a flat 1 for now rather
    // than guess a reference resolution.
    readonly property real baseScale: 1

    // The two fixed pieces that make up this tab's height — matches
    // "Row size + scroll box size" exactly: the header's own height
    // (45, same number the header RowLayout below already uses via
    // Layout.preferredHeight) plus a deliberate target height for the
    // notification list. The list is a clipped, scrollable ListView —
    // it doesn't have (and doesn't need) a "natural" content height,
    // so this is a real design decision, not a measurement.
    readonly property real headerHeight: 45
    readonly property real listTargetHeight: 300
    readonly property real contentMargin: Math.max(15, 25 * baseScale)
    readonly property real contentSpacing: Math.max(10, 15 * baseScale)

    readonly property real cardHeight: Math.max(75, 85 * baseScale)
    readonly property real fontSizeBody: Math.max(11, 14 * baseScale)
    readonly property real fontSizeTitle: Math.max(12, 14 * baseScale)
    readonly property real iconSize: Math.max(50, 40 * baseScale)

    // anchors.fill: parent
    // No implicitWidth — this tab doesn't need an opinion on the
    // drawer's width (same reasoning as Overview.qml). implicitHeight
    // IS needed (tabsLoader depends on it, see above) — composed
    // bottom-up from the fixed constants above, never from root's own
    // live size.
    implicitHeight: headerHeight + contentSpacing + listTargetHeight + contentMargin * 2

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.contentMargin
        spacing: root.contentSpacing

        // ── Header ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight

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
