import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root

    property var menuModel: []
    property int currentIndex: 0
    signal tabClicked(int tabIndex)
    implicitWidth: 220

    ListView {
        anchors.fill: parent
        model: root.menuModel
        spacing: 5
        interactive: false

        delegate: Item {
            width: ListView.view.width
            height: 45

            property bool isHovered: itemMouse.containsMouse
            property bool isSelected: root.currentIndex === index

            Rectangle {
                anchors.fill: parent
                color: Theme.foreground
                opacity: isHovered && !isSelected ? 0.05 : 0
                radius: Theme.radius
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                spacing: 12

                LucideIcon {
                    icon: modelData.icon
                    size: 18
                    color: isSelected ? Theme.selected : Theme.foreground
                    opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.4)

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: modelData.title
                    color: isSelected ? Theme.selected : Theme.foreground
                    font.bold: isSelected
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    opacity: isSelected ? 1.0 : (isHovered ? 0.8 : 0.4)

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.selected
                width: 3
                radius: 2
                opacity: isSelected ? 1 : 0
                height: isSelected ? parent.height * 0.5 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                    }
                }
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: root.tabClicked(index)
            }
        }
    }
}
