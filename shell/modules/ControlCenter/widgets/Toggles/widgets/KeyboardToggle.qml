import QtQuick
import qs.core
import qs.services

ControlButton {
    id: root

    iconText: "keyboard"
    title: KeyboardService.getFull(KeyboardService.currentLayout)
    subtitle: "Layout: " + KeyboardService.getShort(KeyboardService.currentLayout)

    // Το κάνουμε active αν ΔΕΝ είναι η βασική γλώσσα (π.χ. όταν είσαι στα Ελληνικά να ανάβει)
    isActive: KeyboardService.currentLayout !== "us" && KeyboardService.currentLayout !== "en"

    onClicked: {
        console.log("INSIDE");
        let layouts = KeyboardService.availableLayouts;
        if (layouts.length < 2)
            return; // Failsafe

        // Στέλνουμε την εντολή στο Hyprland μέσω του service
        KeyboardService.toggleLayout();
    }
}
