import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.core

BarWidget {
    id: trayWidget

    property var activeMenuHandle: null

    useGradient: true
    visible: trayRepeater.count > 0

    Repeater {
        id: trayRepeater

        model: SystemTray.items

        delegate: Item {
            anchors.verticalCenter: parent.verticalCenter
            height: 20
            width: 20

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                smooth: true
                source: modelData.icon
            }
            MouseArea {
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                opacity: containsMouse ? 0.7 : 1.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate();
                    } else if (mouse.button === Qt.MiddleButton) {
                        modelData.secondaryActivate();
                    } else if (mouse.button === Qt.RightButton) {
                        if (modelData.hasMenu) {
                            if (trayWidget.activeMenuHandle === modelData.menu) {
                                trayWidget.activeMenuHandle = null;
                            } else {
                                trayWidget.activeMenuHandle = modelData.menu;
                            }
                        }
                    }
                }
                onWheel: wheel => {
                    let delta = wheel.angleDelta.y > 0 ? 1 : -1;
                    modelData.scroll(delta, false);
                }
            }
        }
    }
    QsMenuOpener {
        id: menuOpener

        menu: trayWidget.activeMenuHandle
    }
    BarPopup {
        id: customMenuPopup

        showPopup: trayWidget.activeMenuHandle !== null
        targetItem: trayWidget

        ListView {
            id: menuList

            implicitHeight: contentHeight
            interactive: false
            model: menuOpener.children
            spacing: 4
            width: 200

            delegate: Rectangle {
                color: modelData.isSeparator ? Theme.backgroundAlt : (itemMouseArea.containsMouse ? Theme.backgroundAlt : "transparent")
                height: modelData.isSeparator ? 1 : 30
                radius: 6
                width: menuList.width

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8
                    visible: !modelData.isSeparator

                    Image {
                        Layout.preferredHeight: 16
                        Layout.preferredWidth: 16
                        opacity: modelData.icon !== "" ? 1 : 0
                        source: modelData.icon || ""
                    }
                    Text {
                        Layout.fillWidth: true
                        color: Theme.foreground
                        elide: Text.ElideRight
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        text: modelData.text || ""
                    }
                }
                MouseArea {
                    id: itemMouseArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !modelData.isSeparator
                    hoverEnabled: !modelData.isSeparator

                    onClicked: {
                        modelData.triggered();
                        trayWidget.activeMenuHandle = null;
                    }
                }
            }
        }
    }
}
