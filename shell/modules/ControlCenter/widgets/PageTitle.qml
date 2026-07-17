import QtQuick
import qs.core

// Consistent title text for Control Center pages/sections
// ("Control Center", "Wi-Fi", "Bluetooth", "Ethernet", etc.)
// Usage: PageTitle { text: "Wi-Fi" }
Text {
    color: Theme.foreground
    font.family: Theme.fontName
    font.pixelSize: 18
    font.bold: true
}
