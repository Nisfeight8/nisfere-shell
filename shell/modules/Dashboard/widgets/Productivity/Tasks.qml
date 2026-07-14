import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    anchors.fill: parent

    ColumnLayout {
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

        // ── Task list ─────────────────────────────────────────────
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: TasksService.tasks.length > 0
            model: TasksService.tasks
            spacing: 4
            clip: true

            delegate: Rectangle {
                id: row
                property bool isHovered: false

                width: ListView.view.width
                height: 40
                radius: Theme.radius
                color: isHovered ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.1) : Theme.backgroundAlt

                // Behavior on color { AnimColor { type: Anim.FastEffects } }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 6
                    }
                    spacing: 10

                    // Checkbox toggle
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
                            NumberAnimation {
                                duration: 150
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

                HoverHandler {
                    cursorShape: Qt.ArrowCursor
                    onHoveredChanged: row.isHovered = hovered
                }
            }
        }

        // ── Empty state ───────────────────────────────────────────
        ColumnLayout {
            anchors.centerIn: parent
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: TasksService.tasks.length === 0
            spacing: 8

            Item {
                Layout.fillHeight: true
            }
            LucideIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: "list-checks"
                size: 32
                color: Theme.foreground
                opacity: 0.35
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No tasks yet"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12
                opacity: 0.5
            }
            Item {
                Layout.fillHeight: true
            }
        }

        // ── Footer ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            visible: TasksService.tasks.length > 0
            spacing: 8

            Text {
                text: TasksService.remainingCount + " remaining"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 11
                opacity: 0.5
                Layout.fillWidth: true
            }

            IconButton {
                icon: "trash-2"
                size: 26
                iconSize: 12
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                visible: TasksService.completedCount > 0
                hoverColor: Theme.color1
                activeColor: Theme.color1
                tooltipText: "Clear completed"
                onTapped: TasksService.clearCompleted()
            }
        }
    }
}
