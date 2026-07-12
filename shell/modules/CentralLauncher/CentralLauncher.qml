import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services
import "widgets"
import "DockerManager"
PanelWindow {
    id: root

    // ── State ─────────────────────────────────────────────────────
    property int activeTab: 0
    property string activeTool: ""   // "" = home, "docker" = docker manager, etc.

    signal toolRequested(string panel)

    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    // Fullscreen transparent overlay
    anchors.top: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: ShellState.appLauncherOpened
    visible: ShellState.appLauncherOpened

    onActiveTabChanged: {
        searchInput.text = "";
        searchInput.forceActiveFocus();
    }
    onActiveToolChanged: {
        if (activeTool === "")
            searchInput.forceActiveFocus();
    }
    onVisibleChanged: {
        if (visible) {
            searchInput.forceActiveFocus();
            searchInput.text = "";
        }
    }

    // ── Dim background ────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: ShellState.appLauncherOpened ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        MouseArea {
            anchors.fill: parent

            onClicked: ShellState.appLauncherOpened = false
        }
    }

    // ── Centered dialog ───────────────────────────────────────────
    Item {
        anchors.centerIn: parent
        height: 580
        width: 760

        // Glass background
        Rectangle {
            anchors.fill: parent
            border.color: Theme.borderColor
            border.width: 1
            color: Theme.background
            radius: Theme.radius

            // Subtle top gradient
            Rectangle {
                height: parent.height * 0.4
                radius: Theme.radius

                gradient: Gradient {
                    GradientStop {
                        color: Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.04)
                        position: 0.0
                    }
                    GradientStop {
                        color: "transparent"
                        position: 1.0
                    }
                }

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
            }
        }
        ColumnLayout {
            spacing: 12

            anchors {
                fill: parent
                margins: 16
            }

            // ── Tool header (back + title) — shown when a tool is open ──
            Rectangle {
                Layout.fillWidth: true
                border.color: Theme.borderColor
                border.width: 1
                color: Theme.backgroundAlt
                height: 44
                radius: 10
                visible: root.activeTool !== ""

                RowLayout {
                    spacing: 8

                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 14
                    }

                    // Back button
                    Rectangle {
                        id: backBtn

                        property bool isHovered: false

                        color: isHovered ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15) : "transparent"
                        height: 32
                        radius: 8
                        width: 32

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        LucideIcon {
                            anchors.centerIn: parent
                            color: backBtn.isHovered ? Theme.selected : Theme.foreground
                            icon: "arrow-left"
                            size: 16

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
                            onTapped: root.activeTool = ""
                        }
                    }
                    LucideIcon {
                        color: Theme.selected
                        icon: {
                            switch (root.activeTool) {
                            case "docker":
                                return "container";
                            case "git":
                                return "git-branch";
                            case "ssh":
                                return "key";
                            default:
                                return "wrench";
                            }
                        }
                        size: 16
                    }
                    Text {
                        Layout.fillWidth: true
                        color: Theme.foreground
                        font.bold: true
                        font.family: Theme.fontName
                        font.pixelSize: 15
                        text: {
                            switch (root.activeTool) {
                            case "docker":
                                return "Docker Manager";
                            case "git":
                                return "Git Manager";
                            case "ssh":
                                return "SSH Manager";
                            default:
                                return root.activeTool;
                            }
                        }
                    }

                    // Escape hint
                    Text {
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 11
                        opacity: 0.35
                        text: "Esc"
                    }
                }
            }

            // ── Search bar ────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                border.color: searchInput.activeFocus ? Theme.selected : Theme.borderColor
                border.width: 1
                color: Theme.backgroundAlt
                height: 44
                radius: 10
                visible: root.activeTool === ""

                Behavior on border.color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                RowLayout {
                    spacing: 10

                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    LucideIcon {
                        color: Theme.foreground
                        icon: "search"
                        opacity: 0.5
                        size: 16
                    }
                    TextInput {
                        id: searchInput

                        Layout.fillWidth: true
                        clip: true
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 15
                        selectByMouse: true

                        Keys.onPressed: function (e) {
                            switch (e.key) {
                            case Qt.Key_Escape:
                                if (root.activeTool !== "")
                                    root.activeTool = "";
                                else
                                    ShellState.appLauncherOpened = false;
                                e.accepted = true;
                                break;
                            case Qt.Key_Up:
                                if (root.activeTab === 0)
                                    appsPanel.navigate(-appsPanel.columns);
                                e.accepted = true;
                                break;
                            case Qt.Key_Down:
                                if (root.activeTab === 0)
                                    appsPanel.navigate(appsPanel.columns);
                                e.accepted = true;
                                break;
                            case Qt.Key_Left:
                                if (cursorPosition === 0 && root.activeTab === 0)
                                    appsPanel.navigate(-1);
                                break;
                            case Qt.Key_Right:
                                if (cursorPosition === text.length && root.activeTab === 0)
                                    appsPanel.navigate(1);
                                break;
                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                if (root.activeTab === 0 && appsPanel.launchSelected())
                                    ShellState.appLauncherOpened = false;
                                e.accepted = true;
                                break;
                            case Qt.Key_Tab:
                                root.activeTab = (root.activeTab + 1) % 3;
                                e.accepted = true;
                                break;
                            }
                        }

                        // Placeholder
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 15
                            opacity: 0.35
                            text: ["Search apps...", "Search themes & wallpapers...", "Search tools..."][root.activeTab] ?? "Search..."
                            visible: !searchInput.text && !searchInput.activeFocus
                        }
                    }

                    // Clear button
                    LucideIcon {
                        color: Theme.foreground
                        icon: "x"
                        opacity: 0.4
                        size: 14
                        visible: searchInput.text.length > 0

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: searchInput.text = ""
                        }
                    }
                }
            }

            // ── Tab bar ───────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: root.activeTool === ""

                Repeater {
                    model: [
                        {
                            icon: "layout-grid",
                            label: "Apps"
                        },
                        {
                            icon: "sparkles",
                            label: "Appearance"
                        },
                        {
                            icon: "wrench",
                            label: "Tools"
                        },
                    ]

                    Rectangle {
                        id: tabBtn

                        property bool isActive: root.activeTab === index
                        property bool isHovered: false

                        Layout.fillWidth: true
                        border.color: isActive ? Theme.selected : "transparent"
                        border.width: 1
                        color: isActive ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.18) : (isHovered ? Theme.backgroundAlt : "transparent")
                        height: 32
                        radius: 8

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

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            LucideIcon {
                                color: tabBtn.isActive ? Theme.selected : Theme.foreground
                                icon: modelData.icon
                                opacity: tabBtn.isActive ? 1.0 : 0.6
                                size: 13

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
                            Text {
                                color: tabBtn.isActive ? Theme.selected : Theme.foreground
                                font.bold: tabBtn.isActive
                                font.family: Theme.fontName
                                font.pixelSize: 13
                                opacity: tabBtn.isActive ? 1.0 : 0.6
                                text: modelData.label

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
                        }
                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor

                            onHoveredChanged: tabBtn.isHovered = hovered
                        }
                        TapHandler {
                            onTapped: {
                                root.activeTab = index;
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                color: Theme.borderColor
                height: 1
                opacity: 0.4
                visible: root.activeTool === ""
            }

            // ── Panel content ─────────────────────────────────────
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true

                // ── Home panels (visible when no tool is active) ───────
                LauncherAppsPanel {
                    id: appsPanel

                    anchors.fill: parent
                    searchText: searchInput.text
                    visible: root.activeTool === "" && root.activeTab === 0
                }
                LauncherAppearancePanel {
                    anchors.fill: parent
                    searchText: searchInput.text
                    visible: root.activeTool === "" && root.activeTab === 1
                }
                LauncherToolsPanel {
                    anchors.fill: parent
                    searchText: searchInput.text
                    visible: root.activeTool === "" && root.activeTab === 2

                    onToolRequested: panel => root.activeTool = panel
                }

                // ── Tool panels ────────────────────────────────────────
                Loader {
                    active: root.activeTool === "docker"
                    anchors.fill: parent
                    visible: active

                    sourceComponent: Component {
                        DockerManager {
                        }   // ← compile-άρεται στο CentralLauncher context
                    }
                }
            }
        }
    }
}
