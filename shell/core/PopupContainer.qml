import QtQuick
import qs.core

Item {
    id: container

    default property alias content: innerContent.data
    readonly property int invRadius: Theme.radius
    property int padding: 30
    implicitHeight: Math.max(80, innerContent.childrenRect.height + padding *2)
    implicitWidth: Math.max(150, innerContent.childrenRect.width + padding *2)    


    Behavior on opacity {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }
    Behavior on y {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }

    PanelShape {
        anchors.fill: parent
        edge: Qt.TopEdge
    }
    Item {
        id: innerContent
        height: childrenRect.height
        width: childrenRect.width
        x: container.padding
        y: container.padding
    }
}
