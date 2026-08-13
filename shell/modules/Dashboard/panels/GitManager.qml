import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    property real uiScale: 1.0
    required property string repoPath

    // Fixed, deliberate size — same reasoning as every other
    // standalone Dashboard tool (Docker/Settings/SysMon): no floor/
    // ceiling system protects a standalone component's size, so
    // without an explicit one this would collapse to the drawer's
    // bare minimum.
    implicitWidth: 720 * uiScale
    implicitHeight: 640 * uiScale

    anchors.fill: parent

    readonly property string repoName: {
        const parts = repoPath.split("/").filter(p => p !== "");
        return parts.length > 0 ? parts[parts.length - 1] : repoPath;
    }
    readonly property var status: GitService.statusFor(repoPath)
    readonly property var currentError: GitService.errorFor(repoPath)

    Component.onCompleted: GitService.requestStatus(repoPath)

    // Local commit-message draft — cleared after a successful commit
    // (see the Connections below).
    property string commitMessage: ""

    Connections {
        target: GitService
        function onStatusUpdated(repo) {
            if (repo === root.repoPath && commitMessageField.text !== "")
                commitMessageField.text = "";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16 * root.uiScale
        spacing: 12 * root.uiScale

        // ── Header: repo name, branch, ahead/behind, close ────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * root.uiScale

            Rectangle {
                width: 40 * root.uiScale
                height: 40 * root.uiScale
                radius: 10 * root.uiScale
                color: Theme.backgroundAlt
                border.width: 1
                border.color: Theme.borderColor
                LucideIcon {
                    anchors.centerIn: parent
                    icon: "git-branch"
                    size: 18 * root.uiScale
                    color: Theme.selected
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2 * root.uiScale
                Text {
                    text: root.repoName
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 15 * root.uiScale
                    font.bold: true
                    elide: Text.ElideMiddle
                }
                Text {
                    text: {
                        if (!root.status)
                            return root.repoPath;
                        let s = root.status.branch || "(detached)";
                        if (root.status.ahead > 0)
                            s += "  ↑" + root.status.ahead;
                        if (root.status.behind > 0)
                            s += "  ↓" + root.status.behind;
                        return s;
                    }
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11 * root.uiScale
                    opacity: 0.6
                }
            }

            IconButton {
                icon: "refresh-cw"
                size: 30 * root.uiScale
                iconSize: 14 * root.uiScale
                spinning: GitService.loading
                tooltipText: "Refresh"
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.selected
                onTapped: GitService.requestStatus(root.repoPath)
            }

            // Same "X" convention as Docker/SysMon/Settings —
            // ShellState.closeResumableComponent() closes the
            // dashboard AND forgets this as the backgrounded/
            // resumable tool.
            IconButton {
                icon: "x"
                size: 30 * root.uiScale
                iconSize: 14 * root.uiScale
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.color1
                tooltipText: "Close"
                onTapped: ShellState.closeResumableComponent()
            }
        }

        // ── Error banner ───────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            visible: root.currentError !== null
            implicitHeight: errorText.implicitHeight + 16 * root.uiScale
            radius: Theme.radius
            color: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.12)
            border.width: 1
            border.color: Theme.color1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8 * root.uiScale
                spacing: 8 * root.uiScale

                LucideIcon {
                    icon: "alert-triangle"
                    size: 16 * root.uiScale
                    color: Theme.color1
                }
                Text {
                    id: errorText
                    Layout.fillWidth: true
                    text: root.currentError ? ("(" + root.currentError.action + ") " + root.currentError.message) : ""
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12 * root.uiScale
                    wrapMode: Text.WordWrap
                }
            }
        }

        // ── File lists ──────────────────────────────────────────────
        CustomScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 14 * root.uiScale

                GitFileSection {
                    uiScale: root.uiScale
                    title: "Staged"
                    files: root.status ? root.status.staged : []
                    actionIcon: "minus"
                    actionTooltip: "Unstage"
                    onFileAction: file => GitService.unstage(root.repoPath, [file])
                    onSectionAction: () => GitService.unstage(root.repoPath, [])
                    sectionActionTooltip: "Unstage all"
                }
                GitFileSection {
                    uiScale: root.uiScale
                    title: "Changes"
                    files: root.status ? root.status.unstaged : []
                    actionIcon: "plus"
                    actionTooltip: "Stage"
                    onFileAction: file => GitService.stage(root.repoPath, [file])
                    onSectionAction: () => GitService.stage(root.repoPath, root.status ? root.status.unstaged : [])
                    sectionActionTooltip: "Stage all"
                }

                GitFileSection {
                    uiScale: root.uiScale
                    title: "Untracked"
                    files: root.status ? root.status.untracked : []
                    actionIcon: "plus"
                    actionTooltip: "Stage"
                    onFileAction: file => GitService.stage(root.repoPath, [file])
                    onSectionAction: () => GitService.stage(root.repoPath, root.status ? root.status.untracked : [])
                    sectionActionTooltip: "Stage all"
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 20 * root.uiScale
                    visible: root.status && root.status.staged.length === 0 && root.status.unstaged.length === 0 && root.status.untracked.length === 0
                    text: "Working tree clean"
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.foreground
                    opacity: 0.4
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                }
            }
        }

        // ── Commit + push/pull ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * root.uiScale

            SearchBar {
                id: commitMessageField
                Layout.fillWidth: true
                uiScale: root.uiScale
                placeholderText: "Commit message..."
                text: root.commitMessage
                onTextChanged: root.commitMessage = text
            }

            IconButton {
                icon: "check"
                size: 36 * root.uiScale
                iconSize: 16 * root.uiScale
                tooltipText: "Commit staged changes"
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.selected
                enabled: root.commitMessage.trim() !== "" && root.status && root.status.staged.length > 0
                onTapped: GitService.commit(root.repoPath, root.commitMessage.trim())
            }

            IconButton {
                icon: "arrow-down"
                size: 36 * root.uiScale
                iconSize: 16 * root.uiScale
                tooltipText: "Pull"
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.selected
                onTapped: GitService.pull(root.repoPath)
            }

            IconButton {
                icon: "arrow-up"
                size: 36 * root.uiScale
                iconSize: 16 * root.uiScale
                tooltipText: "Push"
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.selected
                onTapped: GitService.push(root.repoPath)
            }
        }
    }


    // ── Reusable file-list section (staged/unstaged/untracked) ─────
    component GitFileSection: ColumnLayout {
        id: section
        property real uiScale: 1.0
        property string title: ""
        property var files: []
        property string actionIcon: ""
        property string actionTooltip: ""
        property string sectionActionTooltip: ""
        signal fileAction(string file)
        signal sectionAction

        Layout.fillWidth: true
        spacing: 4 * uiScale
        visible: files.length > 0

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: section.title + " (" + section.files.length + ")"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12 * section.uiScale
                font.bold: true
                opacity: 0.6
            }
            IconButton {
                icon: "chevrons-" + (section.actionIcon === "plus" ? "up" : "down")
                size: 22 * section.uiScale
                iconSize: 12 * section.uiScale
                tooltipText: section.sectionActionTooltip
                normalColor: "transparent"
                hoverColor: Theme.selected
                onTapped: section.sectionAction()
            }
        }

        Repeater {
            model: section.files
            delegate: RowLayout {
                required property string modelData
                Layout.fillWidth: true
                spacing: 6 * section.uiScale

                Text {
                    Layout.fillWidth: true
                    text: modelData
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12 * section.uiScale
                    elide: Text.ElideMiddle
                }
                IconButton {
                    icon: section.actionIcon
                    size: 22 * section.uiScale
                    iconSize: 12 * section.uiScale
                    tooltipText: section.actionTooltip
                    normalColor: "transparent"
                    hoverColor: Theme.selected
                    onTapped: section.fileAction(modelData)
                }
            }
        }
    }
}
