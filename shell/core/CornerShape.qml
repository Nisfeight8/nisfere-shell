import QtQuick
import QtQuick.Shapes
import qs.core

Item {
    id: root

    property color bgColor: Theme.background
    property color borderColor: Theme.borderColor
    property int edge: Qt.RightEdge
    property int inv: Theme.panelBorderSize   // ταιριάζει με screen border πάχος
    property int r: Theme.radius

    Shape {
        anchors.fill: parent
        layer.enabled: true
        preferredRendererType: Shape.CurveRenderer

        transform: Scale {
            origin.x: root.width / 2
            xScale: root.edge === Qt.LeftEdge ? -1 : 1
        }

        // ── FILL (CW path) ──────────────────────────────────────────
        ShapePath {
            fillColor: root.bgColor
            strokeColor: "transparent"
            startX: root.width
            startY: 0

            // Δεξιά πλευρά (attached στο screen border)
            PathLine {
                x: root.width
                y: root.height
            }

            // Bottom-right: CONCAVE — center (w,h), CCW 90°
            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: root.inv
                radiusY: root.inv
                x: root.width - root.inv
                y: root.height
            }

            // Κάτω πλευρά
            PathLine {
                x: root.r
                y: root.height
            }

            // Bottom-left: CONVEX — center (r, h-r), default CW 90°
            PathArc {
                radiusX: root.r
                radiusY: root.r
                x: 0
                y: root.height - root.r
            }

            // Αριστερή πλευρά (free)
            PathLine {
                x: 0
                y: 0
            }

            // Top-left: CONCAVE — center (0,0), CCW 90°
            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: root.inv
                radiusY: root.inv
                x: 0
                y: 0
            }

            // Πάνω πλευρά (attached στο bar)
            PathLine {
                x: root.width
                y: 0
            }
        }

        // ── BORDER (μόνο ελεύθερες πλευρές) ────────────────────────
        // Path direction: top-left → down left → bottom → bottom-right
        // Σημείωση: ίδια corners, ΑΝΤΙΘΕΤΗ κατεύθυνση διαδρομής
        // → CW/CCW αντιστρέφονται σε σχέση με το fill!
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.borderColor
            strokeWidth: Theme.widgetBorderWidth
            capStyle: ShapePath.FlatCap
            startX: 0
            startY: 0

            // Top-left: CONCAVE — center (0,0), default CW 90°
            // (αντίθετο από fill γιατί έρχεται από δεξιά αντί αριστερά)
            PathArc {
                radiusX: root.inv
                radiusY: root.inv
                x: 0
                y: 0
            }

            // Αριστερή πλευρά κάτω
            PathLine {
                x: 0
                y: root.height - root.r
            }

            // Bottom-left: CONVEX — center (r, h-r), CCW 90°
            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: root.r
                radiusY: root.r
                x: root.r
                y: root.height
            }

            // Κάτω πλευρά δεξιά
            PathLine {
                x: root.width
                y: root.height
            }

            // Bottom-right: CONCAVE — center (w,h), default CW 90°
            PathArc {
                radiusX: root.inv
                radiusY: root.inv
                x: root.width
                y: root.height
            }
            // ✅ Σταματάει εδώ — δεξιά πλευρά καλύπτεται από screen border
        }
    }
}
