import QtQuick
import qs.core
import qs.services

Rectangle {
    id: btn

    property color btnColor: Theme.color4
    property bool isLoading: false
    property string label: "?"

    signal clicked

    border.color: Qt.rgba(btnColor.r, btnColor.g, btnColor.b, ma.containsMouse ? 0.80 : 0.35)
    border.width: 1
    color: ma.containsMouse ? Qt.rgba(btnColor.r, btnColor.g, btnColor.b, 0.28) : Qt.rgba(btnColor.r, btnColor.g, btnColor.b, 0.10)
    enabled: !isLoading
    height: 22
    opacity: isLoading ? 0.5 : 1.0
    radius: Theme.radius
    width: 26

    Behavior on border.color {
        ColorAnimation {
            duration: 80
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: 80
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }

    Text {
        id: btnText

        anchors.centerIn: parent
        color: btn.btnColor
        font.bold: true
        font.pixelSize: 11
        text: btn.isLoading ? "." : btn.label

        SequentialAnimation on text {
            loops: Animation.Infinite
            running: btn.isLoading

            PropertyAction {
                value: "."
            }
            PauseAnimation {
                duration: 250
            }
            PropertyAction {
                value: ".."
            }
            PauseAnimation {
                duration: 250
            }
            PropertyAction {
                value: "..."
            }
            PauseAnimation {
                duration: 250
            }
        }
    }
    MouseArea {
        id: ma

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: {
            btn.isLoading = true;
            btn.clicked();
        }
    }
    Connections {
        function onDataRefreshed() {
            btn.isLoading = false;
        }

        target: DockerService
    }
}
