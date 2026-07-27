import QtQuick
import qs.core
import qs.services

// Same two-mode approach as OSD.qml — see that file's comments for
// the full reasoning.
Item {
    id: root
    anchors.fill: parent

    property bool hasFullscreen: false

    readonly property Item panelItem: modeLoader.item ? modeLoader.item.panelItem : null

    // ── State (shared by both modes) ──────────────────────────────────────
    property var currentNotif: null
    property real notifProgress: 1.0

    readonly property bool hasNotif: currentNotif !== null
    readonly property bool isCritical: hasNotif && currentNotif.isCritical
    readonly property bool hasImage: hasNotif && currentNotif.nImage !== ""
    readonly property bool hasAppIcon: hasNotif && currentNotif.nAppIcon !== ""
    readonly property bool hasActions: hasNotif && currentNotif.actions && currentNotif.actions.length > 0

    property bool shown: hasNotif

    Connections {
        target: NotificationService
        function onShowPopup(notifData) {
            root.currentNotif = notifData;
            hideTimer.restart();
            root.notifProgress = 1.0;
            progressAnim.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 5000
        onTriggered: root.currentNotif = null
    }

    NumberAnimation {
        id: progressAnim
        target: root
        property: "notifProgress"
        from: 1.0
        to: 0.0
        duration: 5000
        easing.type: Easing.Linear
    }

    // ── Mode switch — only ONE of these is ever instantiated ──────────────
    Loader {
        id: modeLoader
        anchors.fill: parent
        sourceComponent: root.hasFullscreen ? popupModeComp : drawerModeComp
    }

    // ── Mode 1: NOT fullscreen — BaseDrawer, cornerMode bottom-right ──────
    Component {
        id: drawerModeComp
        BaseDrawer {
            cornerMode: true
            edge: Qt.RightEdge
            cornerSecondaryEdge: Qt.BottomEdge
            toggleOnHover: false
            openedRequest: root.shown

            contentComponent: Component {
                NotificationContent {
                    currentNotif: root.currentNotif
                    notifProgress: root.notifProgress
                    isCritical: root.isCritical
                    hasImage: root.hasImage
                    hasAppIcon: root.hasAppIcon
                    hasActions: root.hasActions

                    onDismissRequested: root.currentNotif = null
                    onActionInvoked: action => {
                        action.invoke();
                        root.currentNotif = null;
                    }
                }
            }
        }
    }

    // ── Mode 2: fullscreen — simple floating popup, no drawer chrome ─────
    Component {
        id: popupModeComp
        Item {
            id: popupWrapper
            anchors.fill: parent
            readonly property alias panelItem: card

            Rectangle {
                id: card
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    bottomMargin: Theme.panelBorderSize + 20
                    rightMargin: Theme.panelBorderSize + 20
                }
                width: 450
                // FIX — same bug as OSD.qml had: no explicit height
                // means this Rectangle defaults to 0, so with
                // anchors.bottom it renders squashed against the very
                // bottom edge with virtually nothing visible. Bind to
                // the content's own implicitHeight instead.
                height: contentInner.implicitHeight
                radius: Theme.radius
                clip: true
                color: Theme.background
                border.color: Theme.borderColor
                border.width: Theme.widgetBorderWidth

                opacity: root.shown ? 1.0 : 0.0
                transform: Translate {
                    y: root.shown ? 0 : 30
                }
                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                NotificationContent {
                    id: contentInner
                    anchors.fill: parent
                    currentNotif: root.currentNotif
                    notifProgress: root.notifProgress
                    isCritical: root.isCritical
                    hasImage: root.hasImage
                    hasAppIcon: root.hasAppIcon
                    hasActions: root.hasActions

                    onDismissRequested: root.currentNotif = null
                    onActionInvoked: action => {
                        action.invoke();
                        root.currentNotif = null;
                    }
                }
            }
        }
    }
}
