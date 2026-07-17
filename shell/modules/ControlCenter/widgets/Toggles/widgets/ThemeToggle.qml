import QtQuick
import qs.core
import qs.services

ControlButton {
    id: root

    property bool isDark: ThemeService.currentState ? ThemeService.currentState.mode === "dark" : true

    iconText: "palette"
    title: isDark ? "Dark Theme" : "Light Theme"
    subtitle: "Appearance"

    isActive: isDark

    onClicked: {
        ThemeService.toggleMode();
    }
}
