import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"

Rectangle {
    id: root

    Component.onCompleted: console.log("INSIDE CREATION FROM DOCKER WIDGET")
    Component.onDestruction: console.log("INSIDE DESTRUCTION")

    property var expandedProjects: ({})
    property var projectsArray: {
        var out = [];
        var ps = DockerService.composeProjects;
        if (ps && typeof ps === "object") {
            var keys = Object.keys(ps);
            for (var i = 0; i < keys.length; i++) {
                var k = keys[i];
                out.push({
                    name: k,
                    working_dir: ps[k].working_dir || "",
                    config_files: ps[k].config_files || "",
                    containers: ps[k].containers || []
                });
            }
        }
        return out;
    }

    function isExpanded(name) {
        return expandedProjects.hasOwnProperty(name) ? expandedProjects[name] : true;
    }
    function toggleExpanded(name) {
        var copy = Object.assign({}, expandedProjects);
        copy[name] = !isExpanded(name);
        expandedProjects = copy;
    }

    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        // anchors.margins: Theme.padding
        spacing: 6

        // 1. Header
        Rectangle {
            Layout.fillWidth: true
            border.color: Theme.borderColor
            border.width: 1
            color: Theme.backgroundAlt
            height: 54
            radius: Theme.radius - 2

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    color: Theme.selected
                    font.pixelSize: 24
                    text: ""
                }
                Column {
                    spacing: 1

                    Text {
                        color: Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 15
                        text: "Docker"
                    }
                    Text {
                        color: Theme.color8
                        font.family: Theme.fontName
                        font.pixelSize: 10
                        text: root.projectsArray.length + " projects · " + DockerService.standaloneContainers.length + " standalone"
                    }
                }
                Item {
                    Layout.fillWidth: true
                }

                // Running / total badge
                Rectangle {
                    id: badge

                    property color bc: hasError ? Theme.color1 : DockerService.runningContainers > 0 ? Theme.color10 : Theme.color8
                    property bool hasError: DockerService.errorMessage !== ""

                    border.color: Qt.rgba(bc.r, bc.g, bc.b, 0.45)
                    border.width: 1
                    color: Qt.rgba(bc.r, bc.g, bc.b, 0.12)
                    height: 28
                    radius: 14
                    width: badgeText.implicitWidth + 18

                    Text {
                        id: badgeText

                        anchors.centerIn: parent
                        color: badge.bc
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 11
                        text: badge.hasError ? "Error" : DockerService.runningContainers + "/" + DockerService.totalContainers + " running"
                    }
                }
            }
        }

        // 2. Error banner
        Rectangle {
            Layout.fillWidth: true
            border.color: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.40)
            border.width: 1
            color: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.12)
            height: 30
            radius: 8
            visible: DockerService.errorMessage !== ""

            Text {
                color: Theme.color1
                elide: Text.ElideRight
                font.family: Theme.fontName
                font.pixelSize: 11
                text: "⚠  " + DockerService.errorMessage
                verticalAlignment: Text.AlignVCenter

                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }
            }
        }
        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true

            Column {
                spacing: 6
                width: parent.width

                Repeater {
                    model: root.projectsArray

                    delegate: ProjectSection {
                        isExpanded: root.isExpanded(proj.name)
                        proj: modelData

                        onContainerDeleteRequested: (cId, cName) => {
                            delConfirm.container_id = cId;
                            delConfirm.container_name = cName;
                            delConfirm.open();
                        }
                        onToggleRequested: root.toggleExpanded(proj.name)
                    }
                }
                StandaloneSection {
                    containers: DockerService.standaloneContainers

                    onContainerDeleteRequested: (cId, cName) => {
                        delConfirm.container_id = cId;
                        delConfirm.container_name = cName;
                        delConfirm.open();
                    }
                }
            }
        }
    }
    DeleteConfirmModal {
        id: delConfirm
    }
}
