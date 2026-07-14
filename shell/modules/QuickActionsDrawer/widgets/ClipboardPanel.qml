import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    implicitWidth: 420
    implicitHeight: 340

    Component.onCompleted: ClipboardService.refresh()

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ── Header ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            LucideIcon {
                icon: "clipboard-list"
                size: 14
                color: Theme.selected
            }

            Text {
                text: ClipboardService.loading ? "Loading..." : ClipboardService.entries.length + " item" + (ClipboardService.entries.length !== 1 ? "s" : "")
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13
                font.bold: true
                Layout.fillWidth: true
                leftPadding: 4
            }

            IconButton {
                icon: "refresh-cw"
                size: 28
                iconSize: 13
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                tooltipText: "Refresh"
                spinning: ClipboardService.loading
                onTapped: ClipboardService.refresh()
            }

            IconButton {
                icon: "trash-2"
                size: 28
                iconSize: 13
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                visible: ClipboardService.entries.length > 0
                hoverColor: Theme.color1
                activeColor: Theme.color1
                tooltipText: "Clear all"
                onTapped: ClipboardService.wipeAll()
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.4
        }

        // ── Content area — list / loading / empty all share the
        // same footprint (Layout.fillWidth + fillHeight), so each
        // state occupies identical space and centers consistently. ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // List
            ListView {
                anchors.fill: parent
                visible: !ClipboardService.loading && ClipboardService.entries.length > 0
                model: ClipboardService.entries
                spacing: 4
                clip: true

                delegate: Rectangle {
                    id: row
                    property bool isHovered: false

                    width: ListView.view.width
                    height: 40
                    radius: Theme.radius
                    color: isHovered ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.12) : Theme.backgroundAlt

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 6
                        }
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: modelData.preview
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        IconButton {
                            icon: "x"
                            size: 24
                            iconSize: 12
                            // radius: Theme.radius
                            hoverColor: Theme.color1
                            activeColor: Theme.color1
                            idleOpacity: 0.4
                            onTapped: ClipboardService.deleteEntry(modelData.raw)
                        }
                    }

                    HoverHandler {
                        id: hover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: row.isHovered = hovered
                    }
                    TapHandler {
                        onTapped: {
                            ClipboardService.copyEntry(modelData.raw);
                            ShellState.quickActionsOpened = false;
                        }
                    }
                }
            }

            // Loading state
            ColumnLayout {
                anchors.centerIn: parent
                visible: ClipboardService.loading
                spacing: 8

                LucideIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "loader-circle"
                    size: 32
                    color: Theme.foreground
                    opacity: 0.4
                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                        running: ClipboardService.loading
                    }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Loading..."
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    opacity: 0.5
                }
            }

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                visible: !ClipboardService.loading && ClipboardService.entries.length === 0
                spacing: 8

                LucideIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: "clipboard-x"
                    size: 32
                    color: Theme.foreground
                    opacity: 0.35
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No clipboard history"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    opacity: 0.5
                }
            }
        }
    }
}
