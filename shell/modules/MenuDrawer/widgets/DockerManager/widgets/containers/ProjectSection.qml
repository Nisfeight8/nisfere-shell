import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "../../widgets"
import "widgets"
Column {
    id: root

    property bool isExpanded: true
    property var proj: null
    property int projRunning: {
        var n = 0;
        var cs = proj.containers || [];
        for (var i = 0; i < cs.length; i++)
            if (cs[i].status === "running")
                n++;
        return n;
    }

    signal containerDeleteRequested(string cId, string cName) // Push delete

    signal toggleRequested

    spacing: 2
    width: parent.width

    // Project header
    Rectangle {
        border.color: root.isExpanded ? Qt.rgba(Theme.color4.r, Theme.color4.g, Theme.color4.b, 0.50) : Theme.borderColor
        border.width: 1
        color: Theme.backgroundAlt
        height: 58
        radius: Theme.radius
        width: parent.width

        // anchors.margins: 10
        Behavior on border.color {
            ColorAnimation {
                duration: 180
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 14
            spacing: 8

            // Toggle Icon
            Rectangle {
                color: togMa.containsMouse ? Qt.rgba(Theme.color4.r, Theme.color4.g, Theme.color4.b, 0.18) : "transparent"
                height: 20
                radius: 4
                width: 20

                Text {
                    anchors.centerIn: parent
                    color: Theme.color4
                    font.pixelSize: 9
                    text: root.isExpanded ? "▼" : "▶"
                }
                MouseArea {
                    id: togMa

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: root.toggleRequested()
                }
            }
            Column {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    color: Theme.color4
                    font.bold: true
                    font.pixelSize: 13
                    text: "  " + root.proj.name
                }
                Text {
                    color: Theme.color8
                    elide: Text.ElideMiddle
                    font.pixelSize: 10
                    text: root.proj.working_dir || "—"
                    width: 170
                }
            }
            Text {
                color: root.projRunning === root.proj.containers.length ? Theme.color10 : root.projRunning === 0 ? Theme.color8 : Theme.color3
                font.bold: true
                font.pixelSize: 11
                text: root.projRunning + "/" + root.proj.containers.length
            }
            Row {
                spacing: 4

                ActionButton {
                    btnColor: Theme.color10
                    label: "▶"
                    visible: root.projRunning === 0

                    onClicked: DockerService.composeAction("up", root.proj)
                }

                ActionButton {
                    btnColor: Theme.color1
                    label: ""
                    visible: root.projRunning > 0

                    onClicked: DockerService.composeAction("stop", root.proj)
                }

                ActionButton {
                    btnColor: Theme.color3
                    label: "↺"
                    visible: root.projRunning > 0

                    onClicked: DockerService.composeAction("restart", root.proj)
                }

                ActionButton {
                    btnColor: Theme.color9 // Κόκκινο χρώμα διαγραφής
                    label: "✕"

                    onClicked: DockerService.composeAction("down", root.proj)
                }
            }
        }
    }

    // Containers List
    Column {
        bottomPadding: 4
        spacing: 2
        topPadding: 2
        visible: root.isExpanded
        width: parent.width

        Repeater {
            model: root.proj.containers

            delegate: ContainerRow {
                cd: modelData
                width: parent.width - 10
                x: 10
                isStandalone: false
                onDeleteRequested: (cId, cName) => root.containerDeleteRequested(cId, cName)
            }
        }
    }
}
