import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// The notification card's visual content — extracted so it can be
// loaded via BaseDrawer's contentComponent (BaseDrawer now IS the
// NotificationPopup window; see NotificationPopup.qml).
Item {
    id: content

    required property var currentNotif
    required property real notifProgress
    required property bool isCritical
    required property bool hasImage
    required property bool hasAppIcon
    required property bool hasActions

    readonly property bool hasNotif: currentNotif !== null

    // required properties can't be written back to their source — emit
    // signals instead, and let NotificationPopup.qml (which owns
    // currentNotif) react to them.
    signal dismissRequested
    signal actionInvoked(var action)

    implicitWidth: 350
    implicitHeight: mainColumn.implicitHeight + 30

    ColumnLayout {
        id: mainColumn
        anchors {
            fill: parent
            margins: 7
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
                width: parent.width * content.notifProgress
                radius: 2
            }
        }

        // ── Main row: icon + text ─────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: 13

            Rectangle {
                id: iconBadge
                readonly property int _size: content.hasImage ? 80 : 36
                // Computed once, compared as a plain string BEFORE it
                // becomes the Image's url-typed `source` — reading
                // `image.source` back and comparing to "" (as the
                // previous version did) isn't reliable, since `source`
                // is stored as a `url`, not a string (same issue we
                // already fixed once in SystemDrawerHeader.qml's avatar
                // image).
                readonly property string _imageSource: {
                    if (content.hasAppIcon)
                        return content.currentNotif.nAppIcon;
                    if (content.hasImage)
                        return content.currentNotif.nImage;
                    return "";
                }

                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: _size
                Layout.preferredHeight: _size
                border.color: Theme.borderColor
                border.width: Theme.widgetBorderWidth
                color: Theme.backgroundAlt
                radius: Theme.radius * 1.2

                LucideIcon {
                    anchors.centerIn: parent
                    icon: content.isCritical ? "alert-triangle" : "bell"
                    color: content.isCritical ? Theme.color1 : Theme.selected
                    size: 24
                    visible: !content.hasAppIcon && !content.hasImage
                }

                Image {
                    anchors {
                        fill: parent
                        margins: content.hasImage ? 0 : 8
                    }
                    fillMode: Image.PreserveAspectCrop
                    source: iconBadge._imageSource
                    sourceSize.width: iconBadge._size
                    sourceSize.height: iconBadge._size
                    visible: iconBadge._imageSource !== ""
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: content.hasNotif ? content.currentNotif.nAppName.toUpperCase() : ""
                        color: content.isCritical ? Theme.color1 : Theme.selected
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 12
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: content.hasNotif ? content.currentNotif.timeReceived : ""
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 11
                        opacity: 0.6
                    }

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
                            if (content.hasNotif)
                                NotificationService.dismissNotification(content.currentNotif);
                            content.dismissRequested();
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: content.hasNotif ? content.currentNotif.nSummary : ""
                    color: Theme.foreground
                    elide: Text.ElideRight
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 15
                }

                Text {
                    Layout.fillWidth: true
                    text: content.hasNotif ? content.currentNotif.nBody : ""
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
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: content.hasActions

            Repeater {
                model: content.hasActions ? content.currentNotif.actions : []

                delegate: Rectangle {
                    id: actionBtn
                    // Was `property bool isHovered: false` +
                    // `onHoveredChanged: actionBtn.isHovered = hovered`
                    // — simplified to a direct alias, same as the
                    // Tasks.qml/ClipboardPanel.qml fix.
                    readonly property bool isHovered: hover.hovered

                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: Theme.radius
                    border.width: 1
                    border.color: Theme.borderColor
                    color: isHovered ? Theme.selected : "transparent"
                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
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
                            AnimColor {
                                type: Anim.FastEffects
                            }
                        }
                    }

                    HoverHandler {
                        id: hover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: {
                            if (content.hasNotif)
                                NotificationService.dismissNotification(content.currentNotif);
                            content.actionInvoked(modelData);
                        }
                    }
                }
            }
        }
    }
}
