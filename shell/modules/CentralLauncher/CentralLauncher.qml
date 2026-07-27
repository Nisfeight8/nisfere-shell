import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"
import "widgets/LauncherAppsPanel"
import "modules/DockerManager"
import "modules"

Item {
    id: root
    anchors.fill: parent
    focus: true

    Connections {
        target: ShellState
        function onAppLauncherOpenedChanged() {
            if (ShellState.appLauncherOpened) {
                searchBar.text = "";

                if (ShellState.pendingLauncherTool !== "") {
                    ShellState.launcherActiveTab = 1;
                    ShellState.launcherActiveTool = ShellState.pendingLauncherTool;
                    ShellState.pendingLauncherTool = "";
                }
            }
        }

        function onLauncherActiveTabChanged() {
            searchBar.text = "";
            searchBar.input.forceActiveFocus();
        }
        function onLauncherActiveToolChanged() {
            if (ShellState.launcherActiveTool === "")
                searchBar.input.forceActiveFocus();
        }
    }

    // ── Dim background (Scrim) ────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.4)

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.appLauncherOpened = false
        }
    }

    // ── Centered dialog ───────────────────────────────────────────
    Item {
        anchors.centerIn: parent
        width: 760
        height: 580

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.background
            border.width: 1
            border.color: Theme.borderColor

            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: parent.height * 0.4
                radius: Theme.radius
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.04)
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 10
                color: Theme.backgroundAlt
                border.width: 1
                border.color: Theme.borderColor
                visible: ShellState.launcherActiveTool !== ""

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 14
                    }
                    spacing: 8

                    Rectangle {
                        id: backBtn
                        property bool isHovered: false
                        width: 32
                        height: 32
                        radius: 8
                        color: isHovered ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15) : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        LucideIcon {
                            anchors.centerIn: parent
                            icon: "arrow-left"
                            size: 16
                            color: backBtn.isHovered ? Theme.selected : Theme.foreground
                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }
                        }
                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: backBtn.isHovered = hovered
                        }
                        TapHandler {
                            onTapped: ShellState.launcherActiveTool = ""
                        }
                    }

                    LucideIcon {
                        icon: {
                            switch (ShellState.launcherActiveTool) {
                            case "docker":
                                return "container";
                            case "git":
                                return "git-branch";
                            case "ssh":
                                return "key";
                            case "sysmon":
                                return "monitor";
                            default:
                                return "wrench";
                            }
                        }
                        size: 16
                        color: Theme.selected
                    }

                    Text {
                        text: {
                            switch (ShellState.launcherActiveTool) {
                            case "docker":
                                return "Docker Manager";
                            case "git":
                                return "Git Manager";
                            case "ssh":
                                return "SSH Manager";
                            case "sysmon":
                                return "System Monitor";
                            default:
                                return ShellState.launcherActiveTool;
                            }
                        }
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 15
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Esc"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 11
                        opacity: 0.35
                    }
                }
            }

            SearchBar {
                id: searchBar
                visible: ShellState.launcherActiveTool === ""
                Layout.fillWidth: true
                placeholderText: ["Search apps...", "Search tools..."][ShellState.launcherActiveTab] ?? "Search..."

                onKeyPressed: e => {
                    switch (e.key) {
                    case Qt.Key_Escape:
                        if (ShellState.launcherActiveTool !== "")
                            ShellState.launcherActiveTool = "";
                        else
                            ShellState.appLauncherOpened = false;
                        e.accepted = true;
                        break;
                    case Qt.Key_Up:
                        if (ShellState.launcherActiveTab === 0)
                            appsPanel.navigate(-appsPanel.columns);
                        e.accepted = true;
                        break;
                    case Qt.Key_Down:
                        if (ShellState.launcherActiveTab === 0)
                            appsPanel.navigate(appsPanel.columns);
                        e.accepted = true;
                        break;
                    case Qt.Key_Left:
                        if (input.cursorPosition === 0 && ShellState.launcherActiveTab === 0)
                            appsPanel.navigate(-1);
                        break;
                    case Qt.Key_Right:
                        if (input.cursorPosition === text.length && ShellState.launcherActiveTab === 0)
                            appsPanel.navigate(1);
                        break;
                    case Qt.Key_Tab:
                        ShellState.launcherActiveTab = (ShellState.launcherActiveTab + 1) % 2;
                        e.accepted = true;
                        break;
                    }
                }
                onAccepted: {
                    if (ShellState.launcherActiveTab === 0 && appsPanel.launchSelected())
                        ShellState.appLauncherOpened = false;
                }

                // The fix that actually solved the "keyboard only works
                // after a click" bug — see conversation for details.
                Component.onCompleted: input.forceActiveFocus()
            }

            RowLayout {
                visible: ShellState.launcherActiveTool === ""
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        {
                            icon: "layout-grid",
                            label: "Apps"
                        },
                        {
                            icon: "wrench",
                            label: "Tools"
                        }
                    ]

                    NavTile {
                        Layout.fillWidth: true
                        icon: modelData.icon
                        label: modelData.label
                        isActive: ShellState.launcherActiveTab === index
                        hoverColor: Theme.selected
                        activeColor: Theme.selected
                        onTapped: {
                            ShellState.launcherActiveTab = index;
                            searchBar.input.forceActiveFocus();
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderColor
                opacity: 0.4
                visible: ShellState.launcherActiveTool === ""
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                LauncherAppsPanel {
                    id: appsPanel
                    anchors.fill: parent
                    searchText: searchBar.text
                    visible: ShellState.launcherActiveTool === "" && ShellState.launcherActiveTab === 0
                }
                LauncherToolsPanel {
                    anchors.fill: parent
                    searchText: searchBar.text
                    visible: ShellState.launcherActiveTool === "" && ShellState.launcherActiveTab === 1
                    onToolRequested: panel => ShellState.launcherActiveTool = panel
                }

                Loader {
                    anchors.fill: parent
                    active: ShellState.launcherActiveTool === "docker"
                    visible: active
                    sourceComponent: Component {
                        DockerManager {}
                    }
                }

                Loader {
                    anchors.fill: parent
                    active: ShellState.launcherActiveTool === "sysmon"
                    visible: active
                    sourceComponent: Component {
                        SystemMonitorTool {}
                    }
                }
            }
        }
    }
}
