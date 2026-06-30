import QtQuick
import qs.core

Item {
    id: container

    readonly property int botRadius: Theme.radius
    property int bottomPadding: 20
    default property alias content: innerContent.data
    readonly property int invRadius: Theme.radius
    property int leftPadding: 20
    property int rightPadding: 20
    property int topPadding: 20

    implicitHeight: Math.max(80, innerContent.childrenRect.height + topPadding + bottomPadding)
    implicitWidth: Math.max(150, innerContent.childrenRect.width + leftPadding + rightPadding)

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    Behavior on y {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    PanelShape {
        anchors.fill: parent
        edge: Qt.TopEdge
        invRadius: container.invRadius
        normalRadius: container.botRadius
    }
    Item {
        id: innerContent

        height: childrenRect.height
        width: childrenRect.width
        x: container.leftPadding
        y: container.topPadding
    }
}
