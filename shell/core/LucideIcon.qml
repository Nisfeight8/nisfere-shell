import QtQuick
import Quickshell
import QtQuick.Controls.impl

IconImage {
    id: root

    property string icon: "activity"
    property int size: 24

    source: icon ? Quickshell.shellDir + "/assets/icons/" + icon + ".svg" : ""
    sourceSize.width: size
    sourceSize.height: size

    color: "white"
}
