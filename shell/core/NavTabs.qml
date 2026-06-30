import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    property var tabModel: []
    property int currentIndex: 0

    signal tabClicked(int tabIndex)

    spacing: 10

    Repeater {
        model: root.tabModel

        delegate: Item {
            property bool isHovered: tabMouse.containsMouse
            property bool isSelected: root.currentIndex === index

            Layout.fillWidth: true
            Layout.preferredHeight: 45

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

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

            // Το πανέμορφο Animated Underline
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.selected
                height: 3
                opacity: isSelected ? 1 : 0
                radius: 2
                width: isSelected ? parent.width * 0.6 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                    }
                }
            }

            MouseArea {
                id: tabMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: root.tabClicked(index)
            }
        }
    }
}
