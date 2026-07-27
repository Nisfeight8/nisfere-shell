import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

FocusScope {
    id: root
    implicitWidth: 420
    implicitHeight: 340

    focus: true
    Component.onCompleted: {
        ClipboardService.refresh();
        forceActiveFocus();
    }

    // Up/Down navigation is handled natively by ListView itself
    // (keyNavigationEnabled below) — this just handles activating
    // whatever's currently highlighted.
    Keys.onReturnPressed: _activateCurrentEntry()
    Keys.onEnterPressed: _activateCurrentEntry()
    Keys.onSpacePressed: _activateCurrentEntry()

    function _activateCurrentEntry() {
        if (listView.currentIndex < 0 || listView.currentIndex >= ClipboardService.entries.length)
            return;
        const entry = ClipboardService.entries[listView.currentIndex];
        ClipboardService.copyEntry(entry.raw);
        ShellState.quickActionsOpened = false;
    }

    // Entries load asynchronously (refresh() above) — if currentIndex
    // ended up at -1 because the list was still empty when this
    // component completed, make sure it lands on a valid row once
    // entries actually arrive, so keyboard nav/Enter works immediately.
    Connections {
        target: ClipboardService
        function onEntriesChanged() {
            if (listView.currentIndex < 0 && ClipboardService.entries.length > 0)
                listView.currentIndex = 0;
        }
    }

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
                id: listView
                anchors.fill: parent
                visible: !ClipboardService.loading && ClipboardService.entries.length > 0
                model: ClipboardService.entries
                spacing: 4
                clip: true

                // Native keyboard navigation — Up/Down move
                // currentIndex, auto-scrolling to keep it in view.
                focus: true
                keyNavigationEnabled: true
                keyNavigationWraps: true
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 150

                delegate: Rectangle {
                    id: row
                    readonly property bool isHovered: hover.hovered
                    // Keyboard-highlighted row reuses the same tint as
                    // hover — no separate indicator needed.
                    readonly property bool isCurrent: ListView.isCurrentItem

                    width: ListView.view.width
                    height: 40
                    radius: Theme.radius
                    color: (isHovered || isCurrent) ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.12) : Theme.backgroundAlt
                    

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
                    }
                    TapHandler {
                        onTapped: {
                            listView.currentIndex = index;
                            root._activateCurrentEntry();
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
