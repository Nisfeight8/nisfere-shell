import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.services

Item {
    id: root
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 8

        // ── Header row ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            LucideIcon {
                icon: "package-open"
                size: 14
                color: Theme.selected
            }

            Text {
                text: UpdateService.loading ? "Checking..." : UpdateService.updateRunning ? "Updating..." : UpdateService.count > 0 ? UpdateService.count + " update" + (UpdateService.count !== 1 ? "s" : "") + " available" : "System up to date"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13
                font.bold: true
                Layout.fillWidth: true
                leftPadding: 4
            }

            Text {
                text: UpdateService.lastCheck ? "· " + UpdateService.lastCheck : ""
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 11
                opacity: 0.4
            }

            // ── Refresh button ─────────────────────────────────────
            Rectangle {
                id: refreshBtn
                property bool isHovered: false
                width: 30
                height: 30
                radius: 7
                color: isHovered ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.18) : Theme.backgroundAlt
                border.width: isHovered ? 1 : 0
                border.color: Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.4)
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
                Behavior on border.width {
                    NumberAnimation {
                        duration: 150
                    }
                }

                LucideIcon {
                    anchors.centerIn: parent
                    icon: "refresh-cw"
                    size: 14
                    color: refreshBtn.isHovered ? Theme.selected : Theme.foreground
                    opacity: UpdateService.loading ? 0.35 : (refreshBtn.isHovered ? 1.0 : 0.6)
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                        running: UpdateService.loading
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: refreshBtn.isHovered = hovered
                }
                TapHandler {
                    onTapped: if (!UpdateService.loading && !UpdateService.updateRunning)
                        UpdateService.refresh()
                }
                ToolTip {
                    visible: refreshBtn.isHovered
                    text: "Check for updates"
                    delay: 500
                }
            }

            // ── Update All button ──────────────────────────────────
            Rectangle {
                id: updateBtn
                property bool isHovered: false
                visible: UpdateService.count > 0 && !UpdateService.updateRunning
                width: 30
                height: 30
                radius: 7
                color: isHovered ? Qt.rgba(Theme.color2.r, Theme.color2.g, Theme.color2.b, 0.2) : Theme.backgroundAlt
                border.width: isHovered ? 1 : 0
                border.color: Qt.rgba(Theme.color2.r, Theme.color2.g, Theme.color2.b, 0.4)
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
                Behavior on border.width {
                    NumberAnimation {
                        duration: 150
                    }
                }

                LucideIcon {
                    anchors.centerIn: parent
                    icon: "circle-fading-arrow-up"
                    size: 14
                    color: updateBtn.isHovered ? Theme.color2 : Theme.foreground
                    opacity: updateBtn.isHovered ? 1.0 : 0.6
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: updateBtn.isHovered = hovered
                }
                TapHandler {
                    onTapped: UpdateService.runUpdates()
                }
                ToolTip {
                    visible: updateBtn.isHovered
                    text: "Update all packages\n(opens polkit dialog)"
                    delay: 500
                }
            }

            // ── Close log button ───────────────────────────────────
            Rectangle {
                id: closeLogBtn
                property bool isHovered: false
                visible: UpdateService.updateLog.length > 0 && !UpdateService.updateRunning
                width: 30
                height: 30
                radius: 7
                color: isHovered ? Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.15) : Theme.backgroundAlt
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                LucideIcon {
                    anchors.centerIn: parent
                    icon: "x"
                    size: 13
                    color: closeLogBtn.isHovered ? Theme.color1 : Theme.foreground
                    opacity: closeLogBtn.isHovered ? 1.0 : 0.5
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: closeLogBtn.isHovered = hovered
                }
                TapHandler {
                    onTapped: UpdateService.clearLog()
                }
                ToolTip {
                    visible: closeLogBtn.isHovered
                    text: "Clear log"
                    delay: 500
                }
            }
        }

        // ── Live update log ───────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 120
            radius: 8
            color: Theme.backgroundAlt
            visible: UpdateService.updateLog.length > 0
            clip: true

            ListView {
                id: logView
                anchors {
                    fill: parent
                    margins: 8
                }
                model: UpdateService.updateLog
                spacing: 2
                clip: true

                // Auto-scroll to bottom as new lines arrive
                onCountChanged: Qt.callLater(() => positionViewAtEnd())

                delegate: Text {
                    width: logView.width
                    text: modelData
                    color: modelData.startsWith("Error") || modelData.includes("failed") ? Theme.color1 : modelData.includes("✓") || modelData.includes("up to date") ? Theme.color2 : Theme.foreground
                    font.family: "monospace"
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    opacity: 0.9
                }
            }
        }

        // ── Update package list ───────────────────────────────────
        ListView {
            Layout.fillWidth: true
            height: Math.min(UpdateService.count * 26, 130)
            visible: UpdateService.count > 0 && UpdateService.updateLog.length === 0
            model: UpdateService.updates
            clip: true

            delegate: RowLayout {
                width: ListView.view.width
                height: 26
                spacing: 8

                Rectangle {
                    width: 3
                    height: 3
                    radius: 2
                    color: Theme.selected
                    opacity: 0.6
                }
                Text {
                    text: modelData.name
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: modelData.current
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 10
                    opacity: 0.4
                }
                LucideIcon {
                    icon: "arrow-right"
                    size: 10
                    color: Theme.selected
                    opacity: 0.6
                }
                Text {
                    text: modelData.new
                    color: Theme.color2
                    font.family: Theme.fontName
                    font.pixelSize: 11
                }
            }
        }
    }
}
