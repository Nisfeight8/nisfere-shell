import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services

Item {
    id: root
    anchors.fill: parent

    property string filterCategory: "all"   // "all" | "user" | "system"
    property string searchQuery: ""
    property string sortKey: "memMb"
    property bool sortDescending: true

    property var displayList: []

    // pid -> expanded state, survives across refreshes/re-sorts
    property var expandedGroups: ({})

    function toggleExpanded(name) {
        let copy = Object.assign({}, expandedGroups);
        copy[name] = !copy[name];
        expandedGroups = copy;
    }

    function _updateDisplayList() {
        let list = ProcessMonitorService.processes;

        if (filterCategory === "user")
            list = list.filter(p => !p.isSystem);
        else if (filterCategory === "system")
            list = list.filter(p => p.isSystem);

        if (searchQuery.trim() !== "") {
            const q = searchQuery.toLowerCase();
            list = list.filter(p => p.name.toLowerCase().includes(q));
        }

        // Group by name — Electron/Chromium apps (code, spotify, chrome,
        // ...) spawn many OS-level processes for one logical app. One
        // row per app (summed CPU/memory), expandable to see each PID.
        const groupMap = {};
        for (const p of list) {
            let g = groupMap[p.name];
            if (!g) {
                g = {
                    name: p.name,
                    cpuPercent: 0,
                    memMb: 0,
                    isSystem: p.isSystem,
                    pid: p.pid,
                    children: []
                };
                groupMap[p.name] = g;
            }
            g.cpuPercent += p.cpuPercent;
            g.memMb += p.memMb;
            g.children.push(p);
        }

        let grouped = Object.values(groupMap);
        for (const g of grouped) {
            g.cpuPercent = Math.round(g.cpuPercent * 10) / 10;
            g.memMb = Math.round(g.memMb * 10) / 10;
            g.count = g.children.length;
        }

        grouped.sort((a, b) => {
            let av = a[root.sortKey], bv = b[root.sortKey];
            if (typeof av === "string") {
                av = av.toLowerCase();
                bv = bv.toLowerCase();
            }
            if (av < bv)
                return root.sortDescending ? 1 : -1;
            if (av > bv)
                return root.sortDescending ? -1 : 1;
            return 0;
        });

        displayList = grouped;
    }

    onSearchQueryChanged: _updateDisplayList()
    onFilterCategoryChanged: _updateDisplayList()
    onSortKeyChanged: _updateDisplayList()
    onSortDescendingChanged: _updateDisplayList()
    Connections {
        target: ProcessMonitorService
        function onProcessesChanged() {
            root._updateDisplayList();
        }
    }

    Component.onCompleted: {
        ProcessMonitorService.polling = true;
        ProcessMonitorService.refresh();
        _updateDisplayList();
    }
    Component.onDestruction: ProcessMonitorService.polling = false

    function sortBy(key) {
        if (root.sortKey === key)
            root.sortDescending = !root.sortDescending;
        else {
            root.sortKey = key;
            root.sortDescending = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // ── Header ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 44
                    height: 44
                    radius: 12
                    color: Theme.backgroundAlt
                    border.width: 1
                    border.color: Theme.borderColor
                    LucideIcon {
                        anchors.centerIn: parent
                        icon: "monitor"
                        size: 22
                        color: Theme.selected
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: SystemInfo.osName
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 16
                        font.bold: true
                    }
                    Text {
                        text: "Up " + SystemInfo.uptime + " · " + root.displayList.length + " processes"
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 11
                        opacity: 0.55
                    }
                }
            }

            CircularGauge {
                width: 62
                height: 62
                value: SystemStatsService.cpuUsage
                mainText: Math.round(SystemStatsService.cpuUsage * 100) + "%"
                subText: "CPU"
                progressColor: SystemStatsService.cpuUsage > 0.8 ? Theme.color1 : Theme.selected
                showSideText: false
            }

            CircularGauge {
                width: 62
                height: 62
                value: SystemStatsService.ramUsage
                mainText: SystemStatsService.ramUsedText
                subText: "Memory"
                progressColor: Theme.color4
                showSideText: false
            }
        }

        // ── Search + filter ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            SearchBar {
                Layout.fillWidth: true
                placeholderText: "Search processes..."
                text: root.searchQuery
                onTextChanged: root.searchQuery = text
            }

            RowLayout {
                spacing: 6
                Repeater {
                    model: [
                        {
                            key: "all",
                            label: "All"
                        },
                        {
                            key: "user",
                            label: "User"
                        },
                        {
                            key: "system",
                            label: "System"
                        },
                    ]
                    NavTile {
                        implicitWidth: 74
                        icon: ""
                        label: modelData.label
                        isActive: root.filterCategory === modelData.key
                        onTapped: root.filterCategory = modelData.key
                    }
                }
            }
        }

        // ── Table header ─────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Name"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 11
                opacity: 0.5
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.sortBy("name")
                }
            }
            RowLayout {
                Layout.preferredWidth: 70
                spacing: 2
                Text {
                    text: "CPU"
                    color: root.sortKey === "cpuPercent" ? Theme.selected : Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    opacity: root.sortKey === "cpuPercent" ? 1.0 : 0.5
                }
                LucideIcon {
                    visible: root.sortKey === "cpuPercent"
                    icon: root.sortDescending ? "chevron-down" : "chevron-up"
                    size: 11
                    color: Theme.selected
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.sortBy("cpuPercent")
                }
            }
            RowLayout {
                Layout.preferredWidth: 90
                spacing: 2
                Text {
                    text: "Memory"
                    color: root.sortKey === "memMb" ? Theme.selected : Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    font.bold: root.sortKey === "memMb"
                    opacity: root.sortKey === "memMb" ? 1.0 : 0.5
                }
                LucideIcon {
                    visible: root.sortKey === "memMb"
                    icon: root.sortDescending ? "chevron-down" : "chevron-up"
                    size: 11
                    color: Theme.selected
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.sortBy("memMb")
                }
            }
            Text {
                Layout.preferredWidth: 44
                text: "PID"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 11
                opacity: 0.5
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.sortBy("pid")
                }
            }
            // Spacer matching the expand-chevron button's width on each row
            Item {
                Layout.preferredWidth: 20
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.4
        }

        // ── Process list ─────────────────────────────────────────
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.displayList
            spacing: 2

            delegate: Rectangle {
                id: row
                property bool isHovered: false
                readonly property bool isExpanded: !!root.expandedGroups[modelData.name]
                readonly property bool hasMultiple: modelData.count > 1

                width: ListView.view.width
                // Grows to fit expanded child rows (18px each) when toggled open.
                height: 40 + (isExpanded && hasMultiple ? modelData.count * 26 : 0)
                radius: 8
                color: isHovered ? Theme.backgroundAlt : "transparent"
                clip: true
                Behavior on color {
                    AnimColor {
                        type: Anim.FastEffects
                    }
                }
                Behavior on height {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                readonly property string iconName: {
                    const entry = DesktopEntries.heuristicLookup(modelData.name);
                    return (entry && entry.icon) ? entry.icon : "";
                }

                ColumnLayout {
                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 8
                        topMargin: 2
                    }
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        spacing: 8

                        Item {
                            width: 20
                            height: 20
                            Image {
                                id: procIcon
                                anchors.fill: parent
                                source: row.iconName !== "" ? Quickshell.iconPath(row.iconName) : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                            LucideIcon {
                                anchors.centerIn: parent
                                icon: "cpu"
                                size: 14
                                color: Theme.foreground
                                opacity: 0.4
                                visible: procIcon.status !== Image.Ready
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            text: modelData.name
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.preferredWidth: 70
                            text: modelData.cpuPercent.toFixed(1) + "%"
                            color: modelData.cpuPercent > 50 ? Theme.color1 : Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                        }
                        Text {
                            Layout.preferredWidth: 90
                            text: modelData.memMb >= 1024 ? (modelData.memMb / 1024).toFixed(1) + " GB" : modelData.memMb.toFixed(1) + " MB"
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Text {
                            Layout.preferredWidth: 44
                            text: row.hasMultiple ? ("×" + modelData.count) : modelData.pid.toString()
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            opacity: 0.6
                        }
                        IconButton {
                            size: 20
                            iconSize: 13
                            icon: row.isExpanded ? "chevron-up" : "chevron-down"
                            visible: row.hasMultiple
                            normalColor: "transparent"
                            onTapped: root.toggleExpanded(modelData.name)
                        }
                    }

                    // ── Expanded children — individual PIDs ─────────
                    Repeater {
                        model: (row.isExpanded && row.hasMultiple) ? modelData.children : []

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            Layout.leftMargin: 28
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: "PID " + modelData.pid
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 11
                                opacity: 0.6
                            }
                            Text {
                                Layout.preferredWidth: 70
                                text: modelData.cpuPercent.toFixed(1) + "%"
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 11
                                opacity: 0.6
                            }
                            Text {
                                Layout.preferredWidth: 90
                                text: modelData.memMb.toFixed(1) + " MB"
                                color: Theme.foreground
                                font.family: Theme.fontName
                                font.pixelSize: 11
                                opacity: 0.6
                            }
                        }
                    }
                }

                HoverHandler {
                    onHoveredChanged: row.isHovered = hovered
                }
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: root.displayList.length === 0
                text: "No matching processes"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 13
                opacity: 0.4
            }
        }
    }
}
