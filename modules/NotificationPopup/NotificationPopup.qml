import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

BaseDrawer {
    id: popupWindow

    property var currentNotif: null
    property int savedHeight: mainColumn.implicitHeight + 60

    WlrLayershell.layer: WlrLayer.Overlay
    edge: Qt.TopEdge
    edgeMargin: 0
    opened: currentNotif !== null
    panelHeight: savedHeight
    panelWidth: 500
    screenOffset: Theme.barHeight
    toggleOnHover: false

    onCloseRequest: popupWindow.currentNotif = null

    Connections {
        function onShowPopup(notifData) {
            popupWindow.currentNotif = notifData;
            hideTimer.restart();
        }

        target: NotificationService
    }
    Timer {
        id: hideTimer

        interval: 5000

        onTriggered: popupWindow.currentNotif = null
    }
    Item {
        id: mainContainer

        implicitHeight: savedHeight - 10
        width: parent.width

        ColumnLayout {
            id: mainColumn

            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            RowLayout {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                spacing: 13

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredHeight: popupWindow.currentNotif && popupWindow.currentNotif.nImage !== "" ? 120 : 56
                    Layout.preferredWidth: popupWindow.currentNotif && popupWindow.currentNotif.nImage !== "" ? 120 : 56
                    border.color: Theme.borderColor
                    border.width: Theme.widgetBorderWidth
                    color: Theme.backgroundAlt
                    radius: Theme.radius * 1.2

                    Text {
                        anchors.centerIn: parent
                        color: (popupWindow.currentNotif && popupWindow.currentNotif.isCritical) ? Theme.color1 : Theme.selected
                        font.pixelSize: 24
                        text: (popupWindow.currentNotif && popupWindow.currentNotif.isCritical) ? "" : "󰂚"
                        visible: !popupWindow.currentNotif || (popupWindow.currentNotif.nAppIcon === "" && popupWindow.currentNotif.nImage === "")
                    }
                    Image {
                        anchors.fill: parent
                        anchors.margins: popupWindow.currentNotif && popupWindow.currentNotif.nImage !== "" ? 0 : 8
                        fillMode: Image.PreserveAspectCrop
                        source: popupWindow.currentNotif && popupWindow.currentNotif.nAppIcon !== "" ? popupWindow.currentNotif.nAppIcon : (popupWindow.currentNotif && popupWindow.currentNotif.nImage !== "" ? popupWindow.currentNotif.nImage : "")
                        visible: source !== ""
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
                            color: (popupWindow.currentNotif && popupWindow.currentNotif.isCritical) ? Theme.color1 : Theme.selected
                            font.bold: true
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            text: popupWindow.currentNotif ? popupWindow.currentNotif.nAppName.toUpperCase() : ""
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
                            text: popupWindow.currentNotif ? popupWindow.currentNotif.timeReceived : ""
                        }

                        // Close Button
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.leftMargin: 4
                            color: closeMouse.containsMouse ? Theme.color1 : "transparent"
                            height: 24
                            radius: 12
                            width: 24

                            Text {
                                anchors.centerIn: parent
                                color: closeMouse.containsMouse ? Theme.background : Theme.foreground
                                font.pixelSize: 14
                                opacity: closeMouse.containsMouse ? 1.0 : 0.6
                                text: ""
                            }
                            MouseArea {
                                id: closeMouse

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: {
                                    if (popupWindow.currentNotif) {
                                        NotificationService.dismissNotification(popupWindow.currentNotif);
                                    }
                                    popupWindow.currentNotif = null;
                                }
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        color: Theme.foreground
                        elide: Text.ElideRight
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 15
                        text: popupWindow.currentNotif ? popupWindow.currentNotif.nSummary : ""
                    }
                    Text {
                        Layout.fillWidth: true
                        color: Theme.foreground
                        elide: Text.ElideRight
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        maximumLineCount: 3
                        opacity: 0.8
                        text: popupWindow.currentNotif ? popupWindow.currentNotif.nBody : ""
                        wrapMode: Text.Wrap
                    }
                }
            }
            RowLayout {
                Layout.bottomMargin: 20
                Layout.fillWidth: true
                spacing: 12
                visible: popupWindow.currentNotif && popupWindow.currentNotif.actions && popupWindow.currentNotif.actions.length > 0

                Repeater {
                    model: popupWindow.currentNotif ? popupWindow.currentNotif.actions : []

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
                                if (popupWindow.currentNotif) {
                                    NotificationService.dismissNotification(popupWindow.currentNotif);
                                }
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
