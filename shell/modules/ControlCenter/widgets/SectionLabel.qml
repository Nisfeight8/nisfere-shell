import QtQuick
import qs.core

// Small section heading — groups related rows/controls within a
// Control Center sub-page (e.g. "NETWORK", "SECURITY"), sitting below
// a PageHeader. No back button, no navigation — that's PageHeader's
// job; this is purely a label. Caller decides exact casing/wording,
// same as PageTitle.
// Usage: SectionLabel { text: "NETWORK" }
Text {
    id: root
    color: Theme.foreground
    font.family: Theme.fontName
    font.pixelSize: 11
    font.bold: true
    opacity: 0.5
}
