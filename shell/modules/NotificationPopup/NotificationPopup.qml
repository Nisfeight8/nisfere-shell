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

                    Rectangle {
                        readonly property int _size: popupWindow.hasImage ? 120 : 56

                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: _size
                        Layout.preferredHeight: _size
                        border.color: Theme.borderColor
                        border.width: Theme.widgetBorderWidth
                        color: Theme.backgroundAlt
                        radius: Theme.radius * 1.2

                        LucideIcon {
                            anchors.centerIn: parent
                            icon: popupWindow.isCritical ? "alert-triangle" : "bell"
                            color: popupWindow.isCritical ? Theme.color1 : Theme.selected
                            size: 24
                            visible: !popupWindow.hasAppIcon && !popupWindow.hasImage
                        }

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
                            sourceSize.width: parent._size
                            sourceSize.height: parent._size
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
                                text: popupWindow.hasNotif ? popupWindow.currentNotif.nAppName.toUpperCase() : ""
                                color: popupWindow.isCritical ? Theme.color1 : Theme.selected
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: 12
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: popupWindow.hasNotif ? popupWindow.currentNotif.timeReceived : ""
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 11
                                opacity: 0.6
                            }

                            // Close button — hover-solid, matches NotificationCenter style
                            IconButton {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.leftMargin: 4
                                icon: "x"
                                size: 24
                                iconSize: 14
                                radius: 12
                                hoverSolid: true
                                hoverColor: Theme.color1
                                contrastColor: Theme.background
                                fixedIconColor: Theme.foreground
                                idleOpacity: 0.6
                                onTapped: {
                                    if (popupWindow.hasNotif)
                                        NotificationService.dismissNotification(popupWindow.currentNotif);
                                    popupWindow.currentNotif = null;
                                }
                            }
                        }

                        // Summary
                        Text {
                            Layout.fillWidth: true
                            text: popupWindow.hasNotif ? popupWindow.currentNotif.nSummary : ""
                            color: Theme.foreground
                            elide: Text.ElideRight
                            font.bold: true
                            font.family: Theme.fontName
                            font.pixelSize: 15
                        }

                        // Body
                        Text {
                            Layout.fillWidth: true
                            text: popupWindow.hasNotif ? popupWindow.currentNotif.nBody : ""
                            color: Theme.foreground
                            elide: Text.ElideRight
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            maximumLineCount: 3
                            opacity: 0.8
                            wrapMode: Text.Wrap
                        }
                    }
                }

                // ── Actions ───────────────────────────────────────────────
                // Kept as Rectangle — these are full-width text-label buttons,
                // a different shape than the icon-only IconButton component.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: popupWindow.hasActions

                    Repeater {
                        model: popupWindow.hasActions ? popupWindow.currentNotif.actions : []

                        delegate: Rectangle {
                            id: actionBtn
                            property bool isHovered: false

                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: Theme.radius
                            border.width: 1
                            border.color: Theme.borderColor
                            color: isHovered ? Theme.selected : "transparent"
                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.text
                                color: actionBtn.isHovered ? Theme.background : Theme.foreground
                                font.bold: true
                                font.family: Theme.fontName
                                font.pixelSize: 12
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }
                            }

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                                onHoveredChanged: actionBtn.isHovered = hovered
                            }
                            TapHandler {
                                onTapped: {
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
