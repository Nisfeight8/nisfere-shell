import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.services

Item {
    id: root

    property var _filtered: []
    property var _tools: [
        {
            icon: "container",
            label: "Docker",
            sub: "Manage containers",
            panel: "docker",
            ready: true
        },
        {
            icon: "git-branch",
            label: "Git",
            sub: "Repository manager",
            panel: "git",
            ready: false
        },
        {
            icon: "terminal",
            label: "Commands",
            sub: "Quick command runner",
            panel: "commands",
            ready: false
        },
        {
            icon: "calculator",
            label: "Calculator",
            sub: "Built-in calculator",
            panel: "calculator",
            ready: false
        },
        {
            icon: "pipette",
            label: "Color Picker",
            sub: "Pick screen colors",
            panel: "colorpicker",
            ready: false
        },
        {
            icon: "camera",
            label: "Screenshot",
            sub: "Capture screen",
            panel: "screenshot",
            ready: false
        },
        {
            icon: "video",
            label: "Screen Record",
            sub: "Record your screen",
            panel: "recorder",
            ready: false
        },
        {
            icon: "network",
            label: "VPN",
            sub: "VPN connections",
            panel: "vpn",
            ready: false
        },
        {
            icon: "activity",
            label: "System Monitor",
            sub: "Full system stats",
            panel: "sysmon",
            ready: false
        },
        {
            icon: "key",
            label: "SSH",
            sub: "SSH connections",
            panel: "ssh",
            ready: false
        },
    ]
    property string searchText: ""

    signal toolRequested(string panel)

    function _updateFilter() {
        // Explicit assignment forces Repeater model update.
        // A property binding on var→array is not reliably tracked by QML.
        _filtered = _tools.filter(t => root.searchText === "" || t.label.toLowerCase().includes(root.searchText.toLowerCase()) || t.sub.toLowerCase().includes(root.searchText.toLowerCase()));
    }

    implicitHeight: 440
    implicitWidth: 520

    Component.onCompleted: _updateFilter()
    onSearchTextChanged: _updateFilter()

    ScrollView {
        id: scroll

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        anchors.fill: parent
        clip: true
        // ↓ Critical: tell ScrollView how wide the content is
        contentWidth: availableWidth

        GridLayout {
            columnSpacing: 8
            columns: 3
            rowSpacing: 8
            // ↓ Use scroll.availableWidth — NOT parent.width (which is 0 in ScrollView)
            width: scroll.availableWidth

            Repeater {
                model: root._filtered

                Rectangle {
                    id: card

                    property bool isHovered: false

                    // Layout.fillWidth shares the row width equally across 3 columns
                    Layout.fillWidth: true
                    border.color: isHovered && modelData.ready ? Theme.selected : Theme.borderColor
                    border.width: 1
                    color: isHovered && modelData.ready ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15) : Theme.backgroundAlt
                    height: 92
                    opacity: modelData.ready ? 1.0 : 0.5
                    radius: 10

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        width: parent.width - 16

                        LucideIcon {
                            Layout.alignment: Qt.AlignHCenter
                            color: card.isHovered && modelData.ready ? Theme.selected : Theme.foreground
                            icon: modelData.icon
                            size: 24

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            color: Theme.foreground
                            elide: Text.ElideRight
                            font.bold: true
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.label
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            color: Theme.foreground
                            elide: Text.ElideRight
                            font.family: Theme.fontName
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                            opacity: 0.45
                            text: modelData.ready ? modelData.sub : "Coming soon"
                        }
                    }
                    HoverHandler {
                        cursorShape: modelData.ready ? Qt.PointingHandCursor : Qt.ForbiddenCursor

                        onHoveredChanged: card.isHovered = hovered
                    }
                    TapHandler {
                        onTapped: {
                            if (!modelData.ready)
                                return;
                            root.toolRequested(modelData.panel);
                        }
                    }
                }
            }
        }
    }
}
