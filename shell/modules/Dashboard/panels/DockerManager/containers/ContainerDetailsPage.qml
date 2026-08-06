import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.services
import "../shared"

Rectangle {
    id: root

    property string currentStatus: details ? details.status : ""
    property var details: DockerService.activeContainerDetails

    color: Theme.background

    Component.onDestruction: {
        DockerService.isViewingDetails = false;
        DockerService.stopStream();
        DockerService.liveLogs = "";
    }
    onDetailsChanged: {
        if (!details)
            return;

        if (details.status === "running") {
            DockerService.startStream(details.id, details.logs);
        } else {
            DockerService.stopStream();
            if (DockerService.liveLogs === "") {
                DockerService.liveLogs = details.logs || "No logs available";
                DockerService.liveCpu = "0%";
                DockerService.liveRam = "0B";
            }
        }
    }

    Text {
        anchors.centerIn: parent
        color: Theme.color8
        font.family: Theme.fontName
        font.pixelSize: 14
        text: "Select a container to view details and logs"
        visible: !root.details
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 12
        visible: !!root.details

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                border.color: Theme.borderColor
                border.width: 1
                color: backHover.containsMouse ? Theme.backgroundAlt : "transparent"
                height: 32
                radius: Theme.radius
                width: 32

                Text {
                    anchors.centerIn: parent
                    color: Theme.foreground
                    font.pixelSize: 16
                    text: "󰁍"
                }
                MouseArea {
                    id: backHover

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        root.StackView.view.pop(StackView.Immediate);
                        DockerService.activeContainerDetails = null;
                    }
                }
            }

            // Οι πληροφορίες του Container
            Column {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    color: Theme.foreground
                    font.bold: true
                    font.pixelSize: 18
                    text: root.details ? root.details.name : ""
                }
                Text {
                    color: Theme.color8
                    elide: Text.ElideRight
                    font.pixelSize: 11
                    text: "Image: " + (root.details ? root.details.image : "")
                    width: parent.width
                }
            }

            Row {
                spacing: 6

                ActionButton {
                    btnColor: Theme.color10
                    height: 32
                    label: "▶"
                    visible: root.details && root.details.status !== "running"
                    width: 32

                    onClicked: DockerService.containerAction("start", root.details.id)
                }
                ActionButton {
                    btnColor: Theme.color1
                    height: 32
                    label: ""
                    visible: root.details && root.details.status === "running"
                    width: 32

                    onClicked: DockerService.containerAction("stop", root.details.id)
                }
                ActionButton {
                    btnColor: Theme.color3
                    height: 32
                    label: "↺"
                    visible: root.details && root.details.status === "running"
                    width: 32

                    onClicked: DockerService.containerAction("restart", root.details.id)
                }
            }
        }

        // ── STATUS BAR ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            border.color: Theme.borderColor
            border.width: 1
            color: Theme.backgroundAlt
            height: 40
            radius: 6

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12

                Text {
                    color: Theme.color4
                    text: "Status: " + (root.details ? root.details.status : "")
                }
                Item {
                    Layout.fillWidth: true
                }
                Text {
                    color: Theme.color10
                    font.bold: true
                    text: "  CPU: " + DockerService.liveCpu
                }
                Text {
                    color: Theme.color11
                    font.bold: true
                    text: "󰍛 RAM: " + DockerService.liveRam
                }
            }
        }
        Text {
            color: Theme.foreground
            font.bold: true
            font.family: Theme.fontName
            font.pixelSize: 16
            text: "Recent Logs"
        }
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            border.color: Theme.borderColor
            border.width: 1
            color: Theme.backgroundAlt
            radius: Theme.radius

            ScrollView {
                id: logScroll

                anchors.fill: parent
                anchors.margins: 10
                clip: true

                TextEdit {
                    id: logText

                    color: Theme.color2
                    font.family: "Monospace"
                    font.pixelSize: 11
                    readOnly: true
                    selectByMouse: true
                    text: DockerService.liveLogs
                    width: parent.width
                    wrapMode: Text.WrapAnywhere

                    onTextChanged: {
                        logText.cursorPosition = logText.text.length;
                        if (logScroll.ScrollBar.vertical.size < 1.0) {
                            logScroll.ScrollBar.vertical.position = 1.0 - logScroll.ScrollBar.vertical.size;
                        }
                    }
                }
            }
        }
    }
}
