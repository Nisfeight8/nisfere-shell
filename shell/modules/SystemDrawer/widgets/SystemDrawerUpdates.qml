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
            IconButton {
                icon: "refresh-cw"
                size: 30
                iconSize: 14
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                tooltipText: "Check for updates"
                enabled: !UpdateService.loading && !UpdateService.updateRunning
                spinning: UpdateService.loading
                onTapped: UpdateService.refresh()
            }

            // ── Update All button ──────────────────────────────────
            IconButton {
                icon: "circle-fading-arrow-up"
                size: 30
                iconSize: 14
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                visible: UpdateService.count > 0 && !UpdateService.updateRunning
                hoverColor: Theme.color2
                activeColor: Theme.color2
                tooltipText: "Update all packages\nopens polkit dialog"
                onTapped: UpdateService.runUpdates()
            }

            // ── Close log button ───────────────────────────────────
            IconButton {
                icon: "x"
                size: 30
                iconSize: 13
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                visible: UpdateService.updateLog.length > 0 && !UpdateService.updateRunning
                hoverColor: Theme.color1
                activeColor: Theme.color1
                tooltipText: "Clear log"
                onTapped: UpdateService.clearLog()
            }
        }

        // ── Live update log ───────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 120
            radius: Theme.radius
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
                    radius: Theme.radius
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
