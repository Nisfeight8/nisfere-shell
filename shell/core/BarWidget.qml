import QtQuick
import qs.core

Item {
    id: root

    property color bgColor: Theme.backgroundAlt
    default property alias content: contentRow.data
    property int paddingX: 12
    property alias spacing: contentRow.spacing
    property bool useGradient: false

    property int widgetHeight: Theme.barHeight - 15

    implicitHeight: bgRect.implicitHeight
    implicitWidth: bgRect.implicitWidth

    Rectangle {
        id: bgRect

        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: root.useGradient ? "transparent" : root.bgColor
        implicitHeight: root.widgetHeight
        implicitWidth: contentRow.implicitWidth + (root.paddingX * 2)
        radius: Theme.radius

        Behavior on implicitWidth {
            Anim {
                type: Anim.FastSpatial
            }
        }

        GlassBackground {
            visible: root.useGradient
        }
        Row {
            id: contentRow

            anchors.centerIn: parent
            spacing: 8
        }
    }
}
