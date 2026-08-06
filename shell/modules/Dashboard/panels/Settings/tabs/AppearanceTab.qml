import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.services

// Appearance settings — mixed scopes: radius/fontName/
// workspacesPerMonitor live in "shared" (Hyprland needs them too, via
// variables.lua.template), everything else lives in "shell"
// (Quickshell-only). Reads from ThemeState.shared/.shell, writes via
// ThemeActions.setSetting(key, value, scope) with the right scope per
// key — unlike ChromaTab/HyprlandTab, this tab can't hardcode one
// fixed scope for every control.
Item {
    id: root

    readonly property var shared: ThemeState.shared
    readonly property var shell: ThemeState.shell

    // ── Debounced setSetting — scope passed per-call this time,
    // since this tab's keys span both "shared" and "shell". ────────
    property string _pendingKey: ""
    property var _pendingValue: null
    property string _pendingScope: "shared"
    property Timer _debounceTimer: Timer {
        interval: 300
        repeat: false
        onTriggered: ThemeActions.setSetting(root._pendingKey, root._pendingValue, root._pendingScope)
    }
    function _debouncedSet(key, value, scope) {
        root._pendingKey = key;
        root._pendingValue = value;
        root._pendingScope = scope;
        root._debounceTimer.restart();
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 24

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
            }

            // ── General (shared scope) ──────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 12

                Text {
                    text: "General"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Corner Radius"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(radiusSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: radiusSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 40
                        stepSize: 1
                        value: root.shared.radius ?? 20
                        onMoved: root._debouncedSet("radius", Math.round(value), "shared")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Workspaces Per Monitor"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(workspacesSlider.value)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: workspacesSlider
                        Layout.fillWidth: true
                        from: 1
                        to: 20
                        stepSize: 1
                        value: root.shared.workspacesPerMonitor ?? 10
                        onMoved: root._debouncedSet("workspacesPerMonitor", Math.round(value), "shared")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        text: "Font"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13
                    }
                    TextField {
                        id: fontField
                        Layout.fillWidth: true
                        text: root.shared.fontName ?? ""
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        selectByMouse: true

                        background: Rectangle {
                            color: Theme.backgroundAlt
                            radius: Theme.radius / 2
                            border.width: 1
                            border.color: fontField.activeFocus ? Theme.selected : Theme.borderColor

                            Behavior on border.color {
                                AnimColor {
                                    type: Anim.FastEffects
                                }
                            }
                        }

                        // Debounced-on-commit only (Enter or focus
                        // loss), not per-keystroke — a font name isn't
                        // meaningful mid-word, and re-rendering every
                        // template on every typed character would be
                        // wasteful and visually noisy.
                        onEditingFinished: ThemeActions.setSetting("fontName", text, "shared")
                    }
                }
            }

            InfoDivider {
                Layout.leftMargin: 20
                Layout.rightMargin: 20
            }

            // ── Shell layout (shell scope) ───────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 12

                Text {
                    text: "Shell Layout"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Bar Height"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(barHeightSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: barHeightSlider
                        Layout.fillWidth: true
                        from: 30
                        to: 80
                        stepSize: 1
                        value: root.shell.barHeight ?? 50
                        onMoved: root._debouncedSet("barHeight", Math.round(value), "shell")
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Enable Widget Borders"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13
                    }
                    ToggleSwitch {
                        checked: root.shell.enableWidgetBorders ?? true
                        onToggled: ThemeActions.setSetting("enableWidgetBorders", !checked, "shell")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    opacity: enabled ? 1.0 : 0.4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Screen Border Size"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(screenBorderSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: screenBorderSlider
                        Layout.fillWidth: true
                        from: 1
                        to: 20
                        stepSize: 1
                        value: root.shell.screenBorderSize ?? 10
                        onMoved: root._debouncedSet("screenBorderSize", Math.round(value), "shell")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Widget Opacity"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: widgetOpacitySlider.value.toFixed(2)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: widgetOpacitySlider
                        Layout.fillWidth: true
                        from: 0.0
                        to: 1.0
                        value: root.shell.widgetOpacity ?? 1.0
                        onMoved: root._debouncedSet("widgetOpacity", value, "shell")
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 12
            }
        }
    }
}
