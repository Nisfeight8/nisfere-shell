import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import qs.core
import qs.services

BaseDrawer {
    id: popupWindow

    // ── State ────────────────────────────────────────────────────────────
    property var currentNotif: null
    property real notifProgress: 1.0

    // Shorthand — αποφεύγει το currentNotif && currentNotif.x παντού
    readonly property bool hasNotif: currentNotif !== null
    readonly property bool isCritical: hasNotif && currentNotif.isCritical
    readonly property bool hasImage: hasNotif && currentNotif.nImage !== ""
    readonly property bool hasAppIcon: hasNotif && currentNotif.nAppIcon !== ""
    readonly property bool hasActions: hasNotif && currentNotif.actions && currentNotif.actions.length > 0

    // ── BaseDrawer config ─────────────────────────────────────────────────
    asynchronousLoad: false
    WlrLayershell.layer: WlrLayer.Overlay

    edge: Qt.TopEdge
    edgeMargin: 0
    screenOffset: Theme.barHeight
    toggleOnHover: false

    // Fixed width — χωρίς resize ποτέ, BaseDrawer υπολογίζει height κανονικά
    // από το implicitHeight του content (δεν override-άρουμε panelHeight/panelWidth)
    minPanelWidth: 500
    maxPanelWidth: 500

    opened: hasNotif
    onCloseRequest: currentNotif = null

    // ── Notification service ──────────────────────────────────────────────
    Connections {
        target: NotificationService
        function onShowPopup(notifData) {
            popupWindow.currentNotif = notifData;
            hideTimer.restart();
            popupWindow.notifProgress = 1.0;
            progressAnim.restart();
        }
    }

    // ── Timers & animations ───────────────────────────────────────────────
    Timer {
        id: hideTimer
        interval: 5000
        onTriggered: popupWindow.currentNotif = null
    }

    NumberAnimation {
        id: progressAnim
        target: popupWindow
        property: "notifProgress"
        from: 1.0
        to: 0.0
        duration: 5000
        easing.type: Easing.Linear
    }

    // ── Content ───────────────────────────────────────────────────────────
    contentComponent: Component {
        Item {
            id: mainContainer
            implicitHeight: mainColumn.implicitHeight + 30
            width: parent.width

            ColumnLayout {
                id: mainColumn
                anchors {
                    fill: parent
                    margins: 15
                }
                spacing: 12

                // ── Progress bar ──────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 3

                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        color: Theme.selected
                        width: parent.width * popupWindow.notifProgress
                    }
                }

                // ── Main row: icon + text ─────────────────────────────────
                RowLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    spacing: 13

                    // Icon / image
                    Rectangle {
                        readonly property int _size: popupWindow.hasImage ? 120 : 56

                        Layout.alignment: Qt.AlignTop
                        Layout.preferredHeight: _size
                        Layout.preferredWidth: _size
                        border.color: Theme.borderColor
                        border.width: Theme.widgetBorderWidth
                        color: Theme.backgroundAlt
                        radius: Theme.radius * 1.2

                        // Fallback icon — visibile solo quando non c'è immagine
                        LucideIcon {
                            anchors.centerIn: parent
                            color: popupWindow.isCritical ? Theme.color1 : Theme.selected
                            icon: popupWindow.isCritical ? "alert-triangle" : "bell"
                            size: 24
                            visible: !popupWindow.hasAppIcon && !popupWindow.hasImage
                        }

                        // App icon / notification image
                        Image {
                            anchors {
                                fill: parent
                                margins: popupWindow.hasImage ? 0 : 8
                            }
                            
                            fillMode: Image.PreserveAspectCrop
                            source: {
                                if (popupWindow.hasAppIcon)
                                    return popupWindow.currentNotif.nAppIcon;
                                if (popupWindow.hasImage)
                                    return popupWindow.currentNotif.nImage;
                                return "";
                            }
                            sourceSize.height: parent._size
                            sourceSize.width: parent._size
                            visible: source !== ""
                        }
                    }

                    // Text content
                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        spacing: 4

                        // Header row: app name + time + close
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                color: popupWindow.isCritical ? Theme.color1 : Theme.selected
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: 12
                                text: popupWindow.hasNotif ? popupWindow.currentNotif.nAppName.toUpperCase() : ""
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 11
                                opacity: 0.6
                                text: popupWindow.hasNotif ? popupWindow.currentNotif.timeReceived : ""
                            }

                            // Close button
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.leftMargin: 4
                                color: closeMouse.containsMouse ? Theme.color1 : "transparent"
                                height: 24
                                radius: 12
                                width: 24

                                LucideIcon {
                                    anchors.centerIn: parent
                                    color: closeMouse.containsMouse ? Theme.background : Theme.foreground
                                    icon: "x"
                                    opacity: closeMouse.containsMouse ? 1.0 : 0.6
                                    size: 14
                                }

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        if (popupWindow.hasNotif)
                                            NotificationService.dismissNotification(popupWindow.currentNotif);
                                        popupWindow.currentNotif = null;
                                    }
                                }
                            }
                        }

                        // Summary
                        Text {
                            Layout.fillWidth: true
                            color: Theme.foreground
                            elide: Text.ElideRight
                            font.bold: true
                            font.family: Theme.fontName
                            font.pixelSize: 15
                            text: popupWindow.hasNotif ? popupWindow.currentNotif.nSummary : ""
                        }

                        // Body
                        Text {
                            Layout.fillWidth: true
                            color: Theme.foreground
                            elide: Text.ElideRight
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            maximumLineCount: 3
                            opacity: 0.8
                            text: popupWindow.hasNotif ? popupWindow.currentNotif.nBody : ""
                            wrapMode: Text.Wrap
                        }
                    }
                }

                // ── Actions ───────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: popupWindow.hasActions

                    Repeater {
                        model: popupWindow.hasActions ? popupWindow.currentNotif.actions : []

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            border.color: Theme.borderColor
                            border.width: 1
                            color: actionMouse.containsMouse ? Theme.selected : "transparent"
                            radius: Theme.radius

                            Text {
                                anchors.centerIn: parent
                                color: actionMouse.containsMouse ? Theme.background : Theme.foreground
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: 12
                                text: modelData.text
                            }

                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    if (popupWindow.hasNotif)
                                        NotificationService.dismissNotification(popupWindow.currentNotif);
                                    modelData.invoke();
                                    popupWindow.currentNotif = null;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
