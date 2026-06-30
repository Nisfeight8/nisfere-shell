import QtQuick
import Quickshell
import qs.core

// Μόνιμα φορτωμένο, μηδαμινό memory footprint - απλά ανιχνεύει hover σε μια λωρίδα της οθόνης
PanelWindow {
    id: root

    Component.onCompleted: console.log("ΔΗΜΙΟΥΡΓΗΘΗΚΕ")

    property int edge: Qt.RightEdge
    property int zoneSize: Theme.panelBorderSize  // πάχος της λωρίδας ανίχνευσης

    signal hoverEntered

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    // mask: Region {}  // Δεν μπλοκάρει clicks σε ό,τι είναι από κάτω

    readonly property bool isVertical: edge === Qt.LeftEdge || edge === Qt.RightEdge

    anchors {
        left: edge === Qt.LeftEdge
        right: edge === Qt.RightEdge
        top: edge === Qt.TopEdge || isVertical
        bottom: edge === Qt.BottomEdge || isVertical
    }

    implicitWidth: isVertical ? zoneSize : Screen.width
    implicitHeight: isVertical ? Screen.height : zoneSize

    HoverHandler {
        onHoveredChanged: {
            console.log("ON HOVER");
            if (hovered)
                root.hoverEntered();
        }
    }
}
