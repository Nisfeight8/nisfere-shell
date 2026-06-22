import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.core
import qs.services

Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    Connections {
        function onLauncherOpenedChanged() {
            if (ShellState.launcherOpened) {
                searchInput.forceActiveFocus();
            } else {
                searchInput.text = "";
            }
        }

        target: ShellState
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        Rectangle {
            Layout.fillWidth: true
            border.color: searchInput.activeFocus ? Theme.selected : "transparent"
            border.width: Theme.widgetBorderWidth
            color: Theme.backgroundAlt
            height: 40
            radius: Theme.radius

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    color: Theme.foreground
                    font.family: Theme.fontName
                    opacity: 0.6
                    text: ""
                }
                TextInput {
                    id: searchInput

                    Layout.fillWidth: true
                    clip: true
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 14

                    Text {
                        color: Theme.foreground
                        font.family: Theme.fontName
                        opacity: 0.4
                        text: "Search applications..."
                        visible: !searchInput.text && !searchInput.activeFocus
                    }
                }
            }
        }
        ScrollView {
            id: appsScrollView

            Layout.fillHeight: true
            Layout.fillWidth: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            clip: true

            Flow {
                id: appsFlow

                spacing: 0
                width: appsScrollView.width

                Repeater {
                    model: DesktopEntries.applications

                    delegate: Item {
                        property bool isMatch: searchInput.text === "" || modelData.name.toLowerCase().includes(searchInput.text.toLowerCase())

                        clip: true
                        height: isMatch ? 110 : 0
                        visible: isMatch
                        width: isMatch ? (appsFlow.width / 4) : 0

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            radius: Theme.radius

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 6
                                color: Theme.selected
                                opacity: appMouseArea.containsMouse ? 0.2 : 0
                                radius: Theme.radius

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Image {
                                    Layout.alignment: Qt.AlignHCenter
                                    source: "image://icon/" + modelData.icon
                                    sourceSize.height: 48
                                    sourceSize.width: 48
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.maximumWidth: 100
                                    color: Theme.foreground
                                    elide: Text.ElideRight
                                    font.family: Theme.fontName
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    opacity: 0.8
                                    text: modelData.name
                                    wrapMode: Text.Wrap
                                }
                            }
                            MouseArea {
                                id: appMouseArea

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: {
                                    modelData.execute();
                                    ShellState.launcherOpened = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
