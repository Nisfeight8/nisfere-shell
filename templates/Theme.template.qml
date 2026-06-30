pragma Singleton

import QtQuick

QtObject {
    // --- Layout & Styling ---
    readonly property bool enableWidgetBorders: true

    readonly property string fontName: "Arimo Nerd Font"
    readonly property int radius: 15
    readonly property int barHeight: 50
    readonly property int padding: 6

    readonly property int panelBorderSize: 10
    readonly property int widgetBorderWidth: enableWidgetBorders ? 1 : 0

    // Borders: 10% πιο φωτεινά από το φόντο για να ξεχωρίζουν διακριτικά
    readonly property color background: "{{background}}"
    readonly property color foreground: "{{foreground}}"

    // Προσθέτουμε 5% (0.05) από το foreground στο background.
    // Παίζει τέλεια ΚΑΙ σε Dark ΚΑΙ σε Light!
    readonly property color backgroundAlt: Qt.tint(background, Qt.rgba(foreground.r, foreground.g, foreground.b, 0.12))

    readonly property color selected: "{{color4}}"

    // Προσθέτουμε 10% (0.1) από το foreground στο background για τα borders
    readonly property color borderColor: Qt.tint(background, Qt.rgba(foreground.r, foreground.g, foreground.b, 0.18))

    // Για το Highlight Border δεν χρειάζεται saturate του wallust.
    // Αν θες να είναι ελαφρώς πιο σκούρο/έντονο, το QML έχει δικές του συναρτήσεις.
    // Το αφήνουμε απλά ίσο με το επιλεγμένο accent:
    readonly property color highlightBorderColor: selected

    // --- Wallust / 16 Color Palette ---
    readonly property color color0: "{{color0}}"
    readonly property color color1: "{{color1}}"
    readonly property color color2: "{{color2}}"
    readonly property color color3: "{{color3}}"
    readonly property color color4: "{{color4}}"
    readonly property color color5: "{{color5}}"
    readonly property color color6: "{{color6}}"
    readonly property color color7: "{{color7}}"
    readonly property color color8: "{{color8}}"
    readonly property color color9: "{{color9}}"
    readonly property color color10: "{{color10}}"
    readonly property color color11: "{{color11}}"
    readonly property color color12: "{{color12}}"
    readonly property color color13: "{{color13}}"
    readonly property color color14: "{{color14}}"
    readonly property color color15: "{{color15}}"
}
