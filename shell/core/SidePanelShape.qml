import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color bgColor: Theme.background
    property color borderColor: Theme.borderColor
    property int edge: Qt.RightEdge
    property int invRadius: 16
    
    // Το normalRadius δεν χρησιμοποιείται σε αυτό το full-height σχήμα, 
    // αλλά το αφήνουμε ως property για να μην "σπάσει" το API.
    property int normalRadius: Theme.radius

    property int bottomOffset: 0
    property bool cornerAtTop: true

    Shape {
        id: theShape
        anchors.fill: parent
        layer.enabled: true

        transformOrigin: Item.Center
        transform: Scale {
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: root.edge === Qt.LeftEdge ? -1 : 1
            yScale: root.cornerAtTop ? 1 : -1
        }

        // ── FILL ──────────────────────────────────────────────────────
        ShapePath {
            fillColor: root.bgColor
            startX: 0
            startY: 0
            strokeColor: "transparent"

            // 1. Πάνω αριστερά: Inverse γωνία (fillet)
            PathArc {
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: root.invRadius
                y: root.invRadius
            }
            
            // 2. Κατακόρυφη ευθεία προς τα κάτω
            PathLine {
                x: root.invRadius
                y: theShape.height - root.invRadius - root.bottomOffset
            }
            
            // 3. Κάτω αριστερά: Inverse γωνία (fillet)
            PathArc {
                direction: PathArc.Clockwise
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: 0
                y: theShape.height - root.bottomOffset
            }
            
            // 4. Οριζόντια γραμμή προς τα δεξιά (Γεμίζει το κάτω μέρος)
            PathLine {
                x: theShape.width
                y: theShape.height - root.bottomOffset
            }
            
            // 5. Ευθεία γραμμή προς τα πάνω
            PathLine {
                x: theShape.width
                y: 0
            }
            
            // 6. Κλείσιμο (Επιστροφή στην αρχή)
            PathLine {
                x: 0
                y: 0
            }
        }

        // ── BORDER ────────────────────────────────────────────────────
        ShapePath {
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            fillColor: "transparent"
            startX: 0
            startY: 0
            strokeColor: root.borderColor
            strokeWidth: Theme.widgetBorderWidth

            // Πάνω αριστερή εσωτερική καμπύλη
            PathArc {
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: root.invRadius
                y: root.invRadius
            }
            // Αριστερή κάθετη γραμμή
            PathLine {
                x: root.invRadius
                y: theShape.height - root.invRadius - root.bottomOffset
            }
            // Κάτω αριστερή εσωτερική καμπύλη
            PathArc {
                direction: PathArc.Clockwise
                radiusX: root.invRadius
                radiusY: root.invRadius
                x: 0
                y: theShape.height - root.bottomOffset
            }
            
            // ΤΕΛΟΣ BORDER: Ακριβώς όπως στο CornerShape η πάνω πλευρά 
            // δεν έχει γραμμή border, έτσι κι εδώ αφήνουμε την κάτω 
            // πλευρά (bottom edge) "ανοιχτή" χωρίς stroke, για να μην 
            // πατάει πάνω στη χρωματιστή λωρίδα του ScreenBorder!
        }
    }
}