import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.services
import "widgets"

BaseDrawer {
    
    id: root
    cornerMode: true
    anchors.top: true
    margins.top: Theme.barHeight
    edge: Qt.LeftEdge
    opened: ShellState.systemDrawerOpened
    minPanelWidth: Screen.width / 3.4
    minPanelHeight: Screen.width / 3.4

    onCloseRequest: ShellState.systemDrawerOpened = false
    onOpenRequest: ShellState.systemDrawerOpened = true
    onToggleRequest: ShellState.systemDrawerOpened = !ShellState.systemDrawerOpened

    onOpenedChanged: if (opened)
        UpdateService.loadCached()

    contentComponent: Component {
        Item {
            implicitWidth: scroll.width
            implicitHeight: scroll.contentHeight

            ScrollView {
                id: scroll
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 16

                    // ── Header ─────────────────────────────────────────
                    SystemDrawerHeader {
                        Layout.fillWidth: true
                    }

                    // ── Divider ────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.borderColor
                        opacity: 0.35
                    }

                    // ── System Stats ───────────────────────────────────
                    SystemDrawerStats {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // ── Divider ────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.borderColor
                        opacity: 0.35
                    }

                    // ── Arch Updates ───────────────────────────────────
                    SystemDrawerUpdates {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // ── Divider ────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.borderColor
                        opacity: 0.35
                    }

                    // ── Appearance ─────────────────────────────────────
                    SystemDrawerAppearance {
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
