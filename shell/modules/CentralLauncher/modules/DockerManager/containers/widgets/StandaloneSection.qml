import QtQuick
import QtQuick.Layouts
import qs.core

Column {
    id: root

    property var containers: []

    signal containerDeleteRequested(string cId, string cName)

    spacing: 2
    visible: containers.length > 0
    width: parent.width

    Rectangle {
        border.color: Qt.rgba(Theme.color5.r, Theme.color5.g, Theme.color5.b, 0.28)
        border.width: 1
        color: Qt.rgba(Theme.color5.r, Theme.color5.g, Theme.color5.b, 0.08)
        height: 36
        radius: Theme.radius - 4
        width: parent.width

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Text {
                color: Theme.color5
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 12
                text: "⬡  Standalone"
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                property int cnt: root.containers.length

                color: Theme.color8
                font.family: Theme.fontName
                font.pixelSize: 10
                text: cnt + " container" + (cnt !== 1 ? "s" : "")
            }
        }
    }

    Repeater {
        model: root.containers

        delegate: ContainerRow {
            cd: modelData
            isStandalone: true
            onDeleteRequested: (cId, cName) => root.containerDeleteRequested(cId, cName)
        }
    }
}
