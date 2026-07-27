import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core
import qs.services

Item {
    id: root
    anchors.fill: parent
    focus: true
    Component.onCompleted: {
        forceActiveFocus();
    }

    Connections {
        target: ShellState
        function onOverviewOpenChanged() {
            if (ShellState.overviewOpen) {
                root.groupOverride = -1;
                forceActiveFocus();
            }
        }
    }

    // ── Config ─────────────────────────────────────────────────────────────
    readonly property int rows: ShellState.overviewRows
    readonly property int columns: ShellState.overviewColumns
    readonly property bool previewsEnabled: ShellState.overviewPreviewsEnabled
    readonly property bool livePreviews: ShellState.overviewLivePreviews
    property real tileGap: 12

    property int draggingTargetWorkspace: -1
    property int draggingFromWorkspace: -1

    // ── Monitor Context ────────────────────────────────────────────────────
    // Was `visualWindow.monitor` — worked today only because
    // AnimatedContentLoader's created context happens to chain up to
    // shell.qml's PanelWindow (Loader children get a context parented
    // under wherever the Loader itself lives, and id lookup walks that
    // chain) — not because of anything guaranteed by this file. Once
    // ScreenBorder is duplicated per-screen (the actual plan), which
    // specific "visualWindow" that chain resolves to for a given
    // instance becomes ambiguous. QsWindow.window (same attached
    // property BarPopup/BarTooltip already rely on, since standard
    // Qt's Window.window gives an incompatible "ProxiedWindow" here)
    // always reflects the ACTUAL Quickshell window THIS SPECIFIC item
    // ends up in, however many parallel copies of ScreenBorder exist.
    readonly property var _qsWindow: QsWindow.window
    readonly property var currentScreen: _qsWindow ? _qsWindow.screen : null
    readonly property HyprlandMonitor monitor: currentScreen ? Hyprland.monitorFor(currentScreen) : null
    readonly property var monitorData: HyprlandData.monitors.find(m => m.id === monitor?.id)

    // ── Μεγέθη & Υπολογισμοί ──────────────────────────────────────────────
    readonly property var reserved: monitorData?.reserved ?? [0, 0, 0, 0]
    readonly property real availWidth: root.width - reserved[0] - reserved[2]
    readonly property real availHeight: root.height - reserved[1] - reserved[3]

    readonly property int workspacesShown: root.rows * root.columns
    readonly property int currentWorkspaceId: monitor?.activeWorkspace?.id ?? 1
    readonly property int autoGroup: Math.floor((currentWorkspaceId - 1) / workspacesShown)

    property int groupOverride: -1
    readonly property int effectiveGroup: groupOverride >= 0 ? groupOverride : autoGroup

    readonly property real contentWidth: Math.min(availWidth * 0.75, 1020)
    readonly property real tileWidth: (contentWidth - (root.columns + 1) * root.tileGap) / root.columns
    readonly property real tileHeight: tileWidth * (availHeight / availWidth)
    readonly property real tileScale: tileWidth / availWidth

    // ── Scrim Background ──────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.4) // Σκοτεινό φόντο

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.overviewOpen = false
            onWheel: wheel => {
                if (wheel.angleDelta.y > 0)
                    root.groupOverride = Math.max(0, root.effectiveGroup - 1);
                else
                    root.groupOverride = root.effectiveGroup + 1;
            }
        }
    }

    // ── Χειρισμός Πληκτρολογίου (Arrows/Vim bindings) ─────────────────────
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            ShellState.overviewOpen = false;
            event.accepted = true;
            return;
        }

        const currentId = root.monitor?.activeWorkspace?.id ?? 1;
        const total = root.rows * root.columns;
        const idxInGroup = ((currentId - 1) % total + total) % total;

        let row = Math.floor(idxInGroup / root.columns);
        let col = idxInGroup % root.columns;

        if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
            col = (col - 1 + root.columns) % root.columns;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
            col = (col + 1) % root.columns;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            row = (row - 1 + root.rows) % root.rows;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            row = (row + 1) % root.rows;
        } else if (event.key === Qt.Key_PageUp) {
            root.groupOverride = Math.max(0, root.effectiveGroup - 1);
            event.accepted = true;
            return;
        } else if (event.key === Qt.Key_PageDown) {
            root.groupOverride = root.effectiveGroup + 1;
            event.accepted = true;
            return;
        } else {
            return;
        }

        const targetId = root.effectiveGroup * total + row * root.columns + col + 1;
        Hyprland.dispatch(`hl.dsp.focus({ workspace = "${targetId}" })`);
        event.accepted = true;
    }

    // ── Layer για Drag & Drop ─────────────────────────────────────────────
    Item {
        id: dragLayer
        anchors.fill: parent
        z: 10000
    }

    // ── Κεντρικό Container (Grid) ─────────────────────────────────────────
    // Was ALSO doing its own fade+slide-up reveal (reallyOpen/opacity/
    // Translate) on top of AnimatedContentLoader's own fade+scale
    // reveal — the outer loader already owns "content appears
    // smoothly" as a single concern; doing it again here just layers
    // two different motions (scale AND translate) on top of each
    // other. Removed; say the word if you actually want the extra
    // slide-up back as a deliberate, distinct effect.
    Item {
        id: contentCard
        anchors {
            top: parent.top
            topMargin: 20
            horizontalCenter: parent.horizontalCenter
        }
        implicitWidth: grid.implicitWidth + 32
        implicitHeight: grid.implicitHeight + 32

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.background
        }
        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: "transparent"
            border.width: 1
            border.color: Theme.borderColor
        }

        Text {
            anchors {
                top: parent.top
                right: parent.right
                margins: 10
            }
            visible: (HyprlandData.workspaceIds?.length ?? 0) > root.workspacesShown || root.effectiveGroup > 0
            text: (root.effectiveGroup * root.workspacesShown + 1) + "–" + ((root.effectiveGroup + 1) * root.workspacesShown)
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 11
            opacity: 0.4
        }

        GridLayout {
            id: grid
            anchors.centerIn: parent
            columns: root.columns
            rowSpacing: root.tileGap
            columnSpacing: root.tileGap

            Repeater {
                model: root.rows * root.columns

                Rectangle {
                    id: wsTile
                    required property int index
                    readonly property int workspaceId: root.effectiveGroup * root.workspacesShown + index + 1
                    readonly property bool isActive: (root.monitor?.activeWorkspace?.id ?? -1) === workspaceId

                    Layout.preferredWidth: root.tileWidth
                    Layout.preferredHeight: root.tileHeight
                    radius: Theme.radius
                    color: Theme.backgroundAlt
                    border.width: Theme.widgetBorderWidth + (isActive ? 1 : 0)
                    border.color: (root.draggingTargetWorkspace === wsTile.workspaceId) ? Theme.selected : isActive ? Theme.selected : Theme.borderColor
                    clip: true

                    Behavior on border.color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }

                    readonly property int windowCount: HyprlandData.windowList.filter(w => (w.workspace?.id ?? -1) === wsTile.workspaceId).length

                    Text {
                        anchors.centerIn: parent
                        visible: wsTile.windowCount === 0
                        text: wsTile.workspaceId
                        color: Theme.foreground
                        opacity: 0.35
                        font.family: Theme.fontName
                        font.pixelSize: Math.min(root.tileWidth, root.tileHeight) * 0.4
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            ShellState.overviewOpen = false;
                            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${wsTile.workspaceId}" })`);
                        }
                    }

                    Repeater {
                        model: ScriptModel {
                            values: ToplevelManager.toplevels.values.filter(t => {
                                const addr = `0x${t.HyprlandToplevel.address}`;
                                const win = HyprlandData.windowByAddress[addr];
                                return (win?.workspace?.id ?? -1) === wsTile.workspaceId;
                            }).sort((a, b) => {
                                const winA = HyprlandData.windowByAddress[`0x${a.HyprlandToplevel.address}`];
                                const winB = HyprlandData.windowByAddress[`0x${b.HyprlandToplevel.address}`];
                                const floatA = winA?.floating ?? false;
                                const floatB = winB?.floating ?? false;
                                if (floatA !== floatB)
                                    return floatA ? 1 : -1;
                                return 0;
                            })
                        }

                        delegate: WorkspaceOverviewWindow {
                            id: winTile
                            required property var modelData
                            readonly property string address: `0x${modelData.HyprlandToplevel.address}`

                            toplevel: modelData
                            windowData: HyprlandData.windowByAddress[address]
                            tileScale: root.tileScale

                            xOffset: -root.reserved[0] * root.tileScale
                            yOffset: -root.reserved[1] * root.tileScale
                            previewsEnabled: root.previewsEnabled
                            live: root.livePreviews

                            property Item homeParent: null
                            Component.onCompleted: homeParent = winTile.parent

                            onPressedAt: (gx, gy) => {
                                root.draggingFromWorkspace = wsTile.workspaceId;
                                const mapped = winTile.mapToItem(dragLayer, 0, 0);
                                winTile.parent = dragLayer;
                                winTile.x = mapped.x;
                                winTile.y = mapped.y;
                            }

                            onReleased: {
                                const target = root.draggingTargetWorkspace;
                                const from = root.draggingFromWorkspace;
                                root.draggingTargetWorkspace = -1;
                                root.draggingFromWorkspace = -1;

                                winTile.parent = winTile.homeParent;

                                if (target !== -1 && target !== from) {
                                    // follow=false — moves the window without
                                    // also switching your active view to its
                                    // new workspace (that focus-follow is
                                    // what was causing the cursor to warp,
                                    // since you're already looking at the
                                    // overview, not the destination workspace).
                                    Hyprland.dispatch(`hl.dsp.window.move({ workspace = "${target}", follow = false, window = "address:${winTile.address}" })`);
                                } else {
                                    winTile.x = winTile.initX;
                                    winTile.y = winTile.initY;
                                }
                            }
                            onDraggedTo: (gx, gy) => {
                                const pt = grid.mapFromItem(null, gx, gy);
                                const cellW = root.tileWidth + root.tileGap;
                                const cellH = root.tileHeight + root.tileGap;

                                const col = Math.floor(pt.x / cellW);
                                const row = Math.floor(pt.y / cellH);

                                if (row < 0 || row >= root.rows || col < 0 || col >= root.columns) {
                                    root.draggingTargetWorkspace = -1;
                                    return;
                                }

                                const withinX = pt.x - col * cellW;
                                const withinY = pt.y - row * cellH;
                                if (withinX > root.tileWidth || withinY > root.tileHeight) {
                                    root.draggingTargetWorkspace = -1;
                                    return;
                                }

                                root.draggingTargetWorkspace = row * root.columns + col + 1;
                            }
                        }
                    }
                }
            }
        }
    }
}
