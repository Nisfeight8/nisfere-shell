import QtQuick
import Qt5Compat.GraphicalEffects
import qs.core

Item {
    id: root

    property real bgRadius: Theme.radius

    anchors.fill: parent

    Rectangle {
        id: maskShape

        anchors.fill: parent
        radius: root.bgRadius
        visible: false
    }
    Item {
        anchors.fill: parent
        layer.enabled: true

        layer.effect: OpacityMask {
            maskSource: maskShape
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.backgroundAlt
            opacity: 0.65
        }
        LinearGradient {
            anchors.fill: parent
            end: Qt.point(width, height)
            start: Qt.point(0, 0)

            gradient: Gradient {
                GradientStop {
                    color: Qt.alpha(Theme.backgroundAlt, 0.2)
                    position: 0.0
                }
                GradientStop {
                    color: "transparent"
                    position: 0.55
                }
                GradientStop {
                    color: Qt.alpha(Theme.selected, 0.08)
                    position: 1.0
                }
                
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        // border.color: Theme.borderColor
        // border.width: Theme.widgetBorderWidth
        color: "transparent"
        radius: root.bgRadius

        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.widgetBorderWidth
            // border.color: Qt.rgba(1, 1, 1, 0.06)
            // border.width: 1
            color: "transparent"
            radius: Math.max(0, root.bgRadius - 1)
        }
    }
}
