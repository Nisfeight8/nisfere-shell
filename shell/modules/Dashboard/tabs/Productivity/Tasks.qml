import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    anchors.fill: parent
    // Was missing entirely — same fix as Productivity.qml/Media.qml:
    // bottom-up from mainColumn's own (already-correct) implicit size.
    implicitWidth: mainColumn.implicitWidth
    implicitHeight: mainColumn.implicitHeight

    // Deliberate, fixed — NOT the ListView's natural contentHeight.
    // Without this, the ListView below (and the empty-state Item that
    // swaps in for it) has no Layout.preferredHeight, so it defaults
    // to its own content size — meaning mainColumn's implicit height
    // (and therefore this whole tab's, and the whole drawer panel's)
    // would grow or shrink with every task you add/complete/remove.
    // A fixed reserved height keeps the panel stable regardless of
    // task count; the list still scrolls internally via clip: true.
    property real listTargetHeight: 300

    // "active" | "completed" — which list is currently shown
    property string filter: "active"
    property var filteredTasks: []

    // Explicit update pattern — property var bindings with .filter()
    // aren't reliably re-evaluated by QML's dependency tracking, so we
    // recompute imperatively whenever the source data or filter changes.
    function _updateFilteredTasks() {
        filteredTasks = root.filter === "active" ? TasksService.tasks.filter(t => !t.done) : TasksService.tasks.filter(t => t.done);
    }

    onFilterChanged: _updateFilteredTasks()
    Component.onCompleted: _updateFilteredTasks()

    Connections {
        target: TasksService
        function onTasksChanged() {
            root._updateFilteredTasks();
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        spacing: 10

        // ── Add task input ────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 40
            radius: Theme.radius
            color: Theme.backgroundAlt
            border.width: 1
            border.color: input.activeFocus ? Theme.selected : Theme.borderColor
            Behavior on border.color {
                AnimColor {
                    type: Anim.FastEffects
                }
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 8
                }
                spacing: 8

                LucideIcon {
                    icon: "plus"
                    size: 14
                    color: Theme.foreground
                    opacity: 0.5
                }

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    clip: true
                    selectByMouse: true

                    Keys.onReturnPressed: {
                        TasksService.addTask(text);
                        text = "";
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add a task..."
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        opacity: 0.35
                        visible: !input.text && !input.activeFocus
                    }
                }

                IconButton {
                    icon: "arrow-right"
                    size: 26
                    iconSize: 13
                    radius: Theme.radius
                    hoverColor: Theme.selected
                    activeColor: Theme.selected
                    enabled: input.text.trim() !== ""
                    onTapped: {
                        TasksService.addTask(input.text);
                        input.text = "";
                    }
                }
            }
        }

        // ── Active / Completed toggle ──────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    {
                        key: "active",
                        icon: "circle-dashed",
                        label: "Active",
                        count: TasksService.remainingCount
                    },
                    {
                        key: "completed",
                        icon: "check-check",
                        label: "Completed",
                        count: TasksService.completedCount
                    },
                ]

                NavTile {
                    Layout.fillWidth: true
                    icon: modelData.icon
                    label: modelData.label + " (" + modelData.count + ")"
                    isActive: root.filter === modelData.key
                    onTapped: root.filter = modelData.key
                }
            }
        }

        // ── Task list ─────────────────────────────────────────────
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Fixed reserve — see root.listTargetHeight above. Without
            // this, preferredHeight defaults to contentHeight (sum of
            // every task row), making mainColumn's — and therefore the
            // whole drawer's — implicit height grow with task count.
            Layout.preferredHeight: root.listTargetHeight
            visible: root.filteredTasks.length > 0
            model: root.filteredTasks
            spacing: 4
            clip: true

            delegate: Rectangle {
                id: row
                readonly property bool isHovered: rowHover.hovered

                width: ListView.view.width
                height: 40
                radius: Theme.radius
                color: isHovered ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.1) : Theme.backgroundAlt

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 6
                    }
                    spacing: 10

                    Rectangle {
                        id: checkbox
                        width: 20
                        height: 20
                        radius: Theme.radius
                        color: modelData.done ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.9) : "transparent"
                        border.width: 1.5
                        border.color: modelData.done ? Theme.selected : Theme.borderColor
                        Behavior on color {
                            AnimColor {
                                type: Anim.FastEffects
                            }
                        }
                        Behavior on border.color {
                            AnimColor {
                                type: Anim.FastEffects
                            }
                        }

                        LucideIcon {
                            anchors.centerIn: parent
                            icon: "check"
                            size: 12
                            color: Theme.background
                            visible: modelData.done
                        }

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: TasksService.toggleTask(modelData.id)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.text
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        font.strikeout: modelData.done
                        opacity: modelData.done ? 0.4 : 1.0
                        elide: Text.ElideRight
                        Behavior on opacity {
                            Anim {
                                type: Anim.FastEffects
                            }
                        }
                    }

                    IconButton {
                        icon: "x"
                        size: 24
                        iconSize: 12
                        radius: Theme.radius
                        hoverColor: Theme.color1
                        activeColor: Theme.color1
                        idleOpacity: 0.35
                        onTapped: TasksService.removeTask(modelData.id)
                    }
                }

                // Whole-row hover, arrow cursor (not pointing-hand) —
                // this drives only the background tint, not a "click
                // me" affordance; the checkbox/X button each have
                // their own PointingHandCursor for their own actions.
                HoverHandler {
                    id: rowHover
                }
            }
        }

        // ── Empty state ───────────────────────────────────────────
        // Wrapped in a plain Item (safe for Layout.fillWidth/fillHeight)
        // with anchors.centerIn inside it (safe here since the Item
        // itself isn't fighting anchors vs Layout positioning) — more
        // reliable than relying on Layout.alignment resolution when the
        // container itself is a fillWidth child of another Layout.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Same reserved height as the ListView above — so
            // swapping between the populated list and this empty
            // state never changes mainColumn's implicit height either.
            Layout.preferredHeight: root.listTargetHeight
            visible: root.filteredTasks.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                LucideIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: root.filter === "active" ? "list-checks" : "check-check"
                    size: 32
                    color: Theme.foreground
                    opacity: 0.35
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.filter === "active" ? "No active tasks" : "No completed tasks"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    opacity: 0.5
                }
            }
        }

        // ── Footer — clear completed, only relevant on that tab ────
        RowLayout {
            Layout.fillWidth: true
            visible: root.filter === "completed" && TasksService.completedCount > 0
            spacing: 8

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                icon: "trash-2"
                size: 26
                iconSize: 12
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.color1
                activeColor: Theme.color1
                tooltipText: "Clear completed"
                onTapped: TasksService.clearCompleted()
            }
        }
    }
}
