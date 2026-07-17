import QtQuick
import qs.core

Item {
    id: container

    default property alias content: innerContent.data
    readonly property int invRadius: Theme.radius
    property int padding: 30
    implicitHeight: Math.max(80, innerContent.childrenRect.height + padding * 2)
    implicitWidth: Math.max(150, innerContent.childrenRect.width + padding * 2)

    // Same motion split used by BaseDrawer/AnimLoader across the shell:
    // position (y) is a spatial move, opacity is a pure fade/effect —
    // each gets the matching Material-3-derived curve from our Anim system.
    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
    Behavior on y {
        Anim {
            type: Anim.DefaultSpatial
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
