import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "../../../widgets"

Rectangle {
    id: root

    property var cd: null
    property bool isStandalone: false

    signal deleteRequested(string cId, string cName)

    function statusColor(s) {
        if (s === "running")
            return Theme.color10;
        if (s === "restarting")
            return Theme.color3;
        if (s === "paused")
            return Theme.color11;
        if (s === "created")
            return Theme.color6;
        if (s === "dead")
            return Theme.color1;
        return Theme.color8;
    }

    border.color: cd.status === "running" ? Qt.rgba(Theme.color10.r, Theme.color10.g, Theme.color10.b, 0.25) : Qt.rgba(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, 0.40)
    border.width: 1
    color: Theme.backgroundAlt
    height: 42
    radius: Theme.radius
    width: parent.width

    Rectangle {
        anchors.fill: parent
        color: Theme.color4
        opacity: rowMa.containsMouse ? 0.07 : 0.0
        radius: parent.radius

        Behavior on opacity {
            NumberAnimation {
                duration: 80
            }
        }
    }
    MouseArea {
        id: rowMa

        anchors.fill: parent
        cursorShape: !root.isStandalone ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true

        onClicked: {
            if (root.isStandalone)
                return;
            DockerService.requestAndNavigate(root.cd.id);
        }
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Rectangle {
            color: root.statusColor(cd.status)
            height: 8
            radius: 4
            width: 8

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: cd.status === "running"

                NumberAnimation {
                    duration: 950
                    easing.type: Easing.InOutSine
                    to: 0.30
                }
                NumberAnimation {
                    duration: 950
                    easing.type: Easing.InOutSine
                    to: 1.00
                }
            }
        }
        Column {
            Layout.fillWidth: true
            spacing: 1

            Text {
                color: Theme.foreground
                elide: Text.ElideRight
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 12
                text: (cd.service && cd.service !== "N/A") ? cd.service : cd.name
                width: parent.width
            }
            Text {
                color: root.statusColor(cd.status)
                font.family: Theme.fontName
                font.pixelSize: 10
                text: cd.status
            }
        }
        Row {
            spacing: 3

            ActionButton {
                btnColor: Theme.color10
                label: "▶"
                visible: cd.status !== "running"

                onClicked: DockerService.containerAction("start", cd.id)
            }
            ActionButton {
                btnColor: Theme.color1
                label: ""
                visible: cd.status === "running"

                onClicked: DockerService.containerAction("stop", cd.id)
            }
            ActionButton {
                btnColor: Theme.color3
                label: "↺"
                visible: cd.status === "running"

                onClicked: DockerService.containerAction("restart", cd.id)
            }
            ActionButton {
                btnColor: Theme.color9
                label: "✕"

                onClicked: root.deleteRequested(cd.id, cd.name)
            }
        }
    }
}
