import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.services

// Hyprland-only settings (gaps, borders, opacity, blur, shadow,
// cursor). Reads from ThemeState.hyprland, writes via
// ThemeActions.setSetting(key, value, "hyprland").
//
// cursorTheme is DELIBERATELY read-only here, not an editable
// control — ThemeManager._apply_colors() overwrites it automatically
// on every theme change (Bibata-Modern-Classic in light mode,
// -Ice in dark mode, matched for contrast), so an editable control
// would just get silently reset the next time a wallpaper/theme
// changes, same trap the palette colors are in. cursorSize is the one
// genuinely free-standing knob here.
Item {
    id: root

    readonly property var hypr: ThemeState.hyprland

    // ── Debounced setSetting — same idea as ChromaTab's debounce,
    // fixed to the "hyprland" scope since every key on this tab lives
    // there. ─────────────────────────────────────────────────────
    property string _pendingKey: ""
    property var _pendingValue: null
    property Timer _debounceTimer: Timer {
        interval: 300
        repeat: false
        onTriggered: ThemeActions.setSetting(root._pendingKey, root._pendingValue, "hyprland")
    }
    function _debouncedSet(key, value) {
        root._pendingKey = key;
        root._pendingValue = value;
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

            // ── Gaps ─────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 12

                Text {
                    text: "Gaps"
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
                            text: "Workspace Gaps"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(workspaceGapsSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: workspaceGapsSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        stepSize: 2
                        value: root.hypr.workspaceGaps ?? 20
                        onMoved: root._debouncedSet("workspaceGaps", Math.round(value))
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Window Gaps (Inner)"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(gapsInSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: gapsInSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 30
                        stepSize: 1
                        value: root.hypr.windowGapsIn ?? 6
                        onMoved: root._debouncedSet("windowGapsIn", Math.round(value))
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Window Gaps (Outer)"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(gapsOutSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: gapsOutSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 50
                        stepSize: 2
                        value: root.hypr.windowGapsOut ?? 20
                        onMoved: root._debouncedSet("windowGapsOut", Math.round(value))
                    }
                }
            }

            InfoDivider {
                Layout.leftMargin: 20
                Layout.rightMargin: 20
            }

            // ── Borders ──────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 4

                Text {
                    text: "Borders"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Border Size"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13
                    }
                    Text {
                        text: Math.round(borderSizeSlider.value) + "px"
                        color: Theme.selected
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        font.bold: true
                    }
                }
                CustomSlider {
                    id: borderSizeSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 10
                    stepSize: 1
                    value: root.hypr.windowBorderSize ?? 2
                    onMoved: root._debouncedSet("windowBorderSize", Math.round(value))
                }
            }

            InfoDivider {
                Layout.leftMargin: 20
                Layout.rightMargin: 20
            }

            // ── Opacity ──────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 12

                Text {
                    text: "Opacity"
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
                            text: "Active Window"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: opacityActiveSlider.value.toFixed(2)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: opacityActiveSlider
                        Layout.fillWidth: true
                        from: 0.0
                        to: 1.0
                        value: root.hypr.opacityActive ?? 0.95
                        onMoved: root._debouncedSet("opacityActive", value)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Inactive Window"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: opacityInactiveSlider.value.toFixed(2)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: opacityInactiveSlider
                        Layout.fillWidth: true
                        from: 0.0
                        to: 1.0
                        value: root.hypr.opacityInactive ?? 0.85
                        onMoved: root._debouncedSet("opacityInactive", value)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Fullscreen Window"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: opacityFullscreenSlider.value.toFixed(2)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: opacityFullscreenSlider
                        Layout.fillWidth: true
                        from: 0.0
                        to: 1.0
                        value: root.hypr.opacityFullscreen ?? 1.0
                        onMoved: root._debouncedSet("opacityFullscreen", value)
                    }
                }
            }

            InfoDivider {
                Layout.leftMargin: 20
                Layout.rightMargin: 20
            }

            // ── Blur ─────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Blur"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        font.bold: true
                    }
                    ToggleSwitch {
                        checked: root.hypr.blurEnabled ?? true
                        onToggled: ThemeActions.setSetting("blurEnabled", !checked, "hyprland")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    enabled: root.hypr.blurEnabled ?? true
                    opacity: enabled ? 1.0 : 0.4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Blur Size"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(blurSizeSlider.value)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: blurSizeSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 20
                        stepSize: 1
                        value: root.hypr.blurSize ?? 8
                        onMoved: root._debouncedSet("blurSize", Math.round(value))
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Blur Passes"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(blurPassesSlider.value)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: blurPassesSlider
                        Layout.fillWidth: true
                        from: 1
                        to: 5
                        stepSize: 1
                        value: root.hypr.blurPasses ?? 3
                        onMoved: root._debouncedSet("blurPasses", Math.round(value))
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Blur Popups"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        ToggleSwitch {
                            checked: root.hypr.blurPopups ?? true
                            onToggled: ThemeActions.setSetting("blurPopups", !checked, "hyprland")
                        }
                    }
                }
            }

            InfoDivider {
                Layout.leftMargin: 20
                Layout.rightMargin: 20
            }

            // ── Shadow ───────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Shadow"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        font.bold: true
                    }
                    ToggleSwitch {
                        checked: root.hypr.shadowEnabled ?? true
                        onToggled: ThemeActions.setSetting("shadowEnabled", !checked, "hyprland")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    enabled: root.hypr.shadowEnabled ?? true
                    opacity: enabled ? 1.0 : 0.4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Shadow Range"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(shadowRangeSlider.value) + "px"
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: shadowRangeSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 50
                        stepSize: 1
                        value: root.hypr.shadowRange ?? 15
                        onMoved: root._debouncedSet("shadowRange", Math.round(value))
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Shadow Render Power"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(shadowPowerSlider.value)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: shadowPowerSlider
                        Layout.fillWidth: true
                        from: 1
                        to: 4
                        stepSize: 1
                        value: root.hypr.shadowRenderPower ?? 4
                        onMoved: root._debouncedSet("shadowRenderPower", Math.round(value))
                    }
                }
            }

            InfoDivider {
                Layout.leftMargin: 20
                Layout.rightMargin: 20
            }

            // ── Cursor ───────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 12

                Text {
                    text: "Cursor"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }

                // Read-only — auto-managed by the daemon per dark/
                // light mode (Bibata-Modern-Ice / -Classic), overwritten
                // on every theme change. See file-level comment.
                InfoRow {
                    Layout.fillWidth: true
                    label: "Cursor Theme"
                    value: root.hypr.cursorTheme ?? "—"
                }
                Text {
                    Layout.fillWidth: true
                    text: "Auto-selected for contrast with the current mode — not directly editable."
                    color: Theme.foreground
                    opacity: 0.45
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Cursor Size"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(cursorSizeSlider.value)
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    CustomSlider {
                        id: cursorSizeSlider
                        Layout.fillWidth: true
                        from: 16
                        to: 48
                        stepSize: 4
                        value: root.hypr.cursorSize ?? 24
                        onMoved: root._debouncedSet("cursorSize", Math.round(value))
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
