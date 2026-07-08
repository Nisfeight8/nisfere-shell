import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color bgColor: Theme.background
    property color borderColor: Theme.borderColor
    property int edge: Qt.RightEdge
    property int invRadius: 16
    property int normalRadius: Theme.radius

    property int bottomOffset: 0

    Shape {
        id: theShape
        anchors.fill: parent
        layer.enabled: true

        transformOrigin: Item.Center
        transform: Scale {
            origin.x: root.width / 2
            xScale: root.edge === Qt.LeftEdge ? -1 : 1
        }

        // ── FILL ──────────────────────────────────────────────────────
        ShapePath {
            fillColor: root.bgColor
            startX: 0
            startY: 0
            strokeColor: "transparent"

            // 1. Top-Left (Ελεύθερη): Inverted (Σκάβει μέσα)
            PathArc {
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: root.invRadius
                y: root.invRadius
            }
            // 2. Left Edge: Κατεβαίνει και αφήνει χώρο ΚΑΙ για το πάτωμα ΚΑΙ για την καμπύλη ΚΑΙ αφαιρούμε το offset
            PathLine {
                x: root.invRadius
                y: theShape.height - root.invRadius - root.normalRadius - root.bottomOffset
            }
            // 3. Bottom-Left (Ελεύθερη): Normal (Κυρτό) - Πιο πάνω κατά το offset
            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: root.normalRadius
                radiusY: root.normalRadius
                x: root.invRadius + root.normalRadius
                y: theShape.height - root.invRadius - root.bottomOffset
            }
            // 4. Bottom Edge: Σταματάει πιο ψηλά (αφήνει κενό από κάτω + το offset)
            PathLine {
                x: theShape.width - root.invRadius
                y: theShape.height - root.invRadius - root.bottomOffset
            }
            // 5. Bottom-Right: Η κοίλη καμπύλη που απλώνει προς τη γωνία - Ανεβασμένη κατά το offset
            PathArc {
                direction: PathArc.Clockwise
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: theShape.width
                y: theShape.height - root.bottomOffset
            }
            // 6. Right Edge (Attached): Φεύγει κατευθείαν από τη γωνία και ανεβαίνει
            PathLine {
                x: theShape.width
                y: 0
            }
            // 7. Top Edge (Attached): Κλείνει αριστερά
            PathLine {
                x: 0
                y: 0
            }
        }

        // ── BORDER ────────────────────────────────────────────────────
        // Είναι καρμπόν το ίδιο Path με το Fill, αλλά σταματάει
        // εκεί που ακουμπάει σε οθόνη (Right/Top edge)
        ShapePath {
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            fillColor: "transparent"
            startX: 0
            startY: 0
            strokeColor: root.borderColor
            strokeWidth: Theme.widgetBorderWidth

            // 1. Top-Left: Inverted
            PathArc {
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: root.invRadius
                y: root.invRadius
            }
            // 2. Left Edge: Αφαιρούμε το offset
            PathLine {
                x: root.invRadius
                y: theShape.height - root.invRadius - root.normalRadius - root.bottomOffset
            }
            // 3. Bottom-Left: Αφαιρούμε το offset
            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: root.normalRadius
                radiusY: root.normalRadius
                x: root.invRadius + root.normalRadius
                y: theShape.height - root.invRadius - root.bottomOffset
            }
            // 4. Bottom Edge: Αφαιρούμε το offset
            PathLine {
                x: theShape.width - root.invRadius
                y: theShape.height - root.invRadius - root.bottomOffset
            }
            // 5. Bottom-Right: Αφαιρούμε το offset
            PathArc {
                direction: PathArc.Clockwise
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: theShape.width
                y: theShape.height - root.bottomOffset
            }
            // 6. Right Edge (Attached): Φεύγει κατευθείαν από τη γωνία και ανεβαίνει

            // Σταματάει εδώ! Δεν τραβάει PathLine για δεξιά και πάνω πλευρά.
        }
    }
}
