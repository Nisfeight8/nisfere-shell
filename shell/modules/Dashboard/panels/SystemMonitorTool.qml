import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services

Item {
    id: root

    // Fixed, deliberate size — same reasoning as Settings.qml: this is
    // a standalone top-level Dashboard component now (see
    // ShellState.dashboardActiveComponent), not part of TabsComponent's
    // floor/ceiling system. Previously had no implicit size at all,
    // meaning DashboardContent's AnimLoader saw 0×0 and the whole
    // drawer panel collapsed to its bare minimum whenever this opened.
    implicitWidth: 820
    implicitHeight: 600

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

    // Pure grouping/filtering — no sort applied. Shared by both the
    // "explicit action" and "passive refresh" paths below so the
    // filter/group logic exists in exactly one place.
    function _recomputeGroups() {
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

        const grouped = Object.values(groupMap);
        for (const g of grouped) {
            g.cpuPercent = Math.round(g.cpuPercent * 10) / 10;
            g.memMb = Math.round(g.memMb * 10) / 10;
            g.count = g.children.length;
        }
        return grouped;
    }

    function _sortGroups(grouped) {
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
        return grouped;
    }

    // Explicit user action (typed search, clicked a filter tile or a
    // column header) — always re-sorts immediately, even while
    // hovering the list; you asked for this order right now.
    function _updateDisplayListSorted() {
        displayList = _sortGroups(_recomputeGroups());
    }

    // Passive refresh (the 3s poll tick from ProcessMonitorService) —
    // while the pointer is over the list (listHoverHandler.hovered),
    // keep row POSITIONS stable instead of re-sorting, so a live CPU/
    // RAM number tick doesn't yank a row out from under your cursor
    // mid-click. Values still refresh live either way — only the
    // ordering freezes, and only for this passive path.
    function _updateDisplayListLive() {
        const grouped = root._recomputeGroups();
        if (!listHoverHandler.hovered) {
            displayList = root._sortGroups(grouped);
            return;
        }
        const byName = new Map(grouped.map(g => [g.name, g]));
        const ordered = [];
        for (const prev of root.displayList) {
            if (byName.has(prev.name)) {
                ordered.push(byName.get(prev.name));
                byName.delete(prev.name);
            }
        }
        // Any brand-new process group that appeared while frozen goes
        // on the end rather than being dropped.
        for (const g of byName.values())
            ordered.push(g);
        displayList = ordered;
    }

    onSearchQueryChanged: _updateDisplayListSorted()
    onFilterCategoryChanged: _updateDisplayListSorted()
    onSortKeyChanged: _updateDisplayListSorted()
    onSortDescendingChanged: _updateDisplayListSorted()
    Connections {
        target: ProcessMonitorService
        function onProcessesChanged() {
            root._updateDisplayListLive();
        }
    }

    Component.onCompleted: {
        ProcessMonitorService.polling = true;
        ProcessMonitorService.refresh();
        _updateDisplayListSorted();
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
                Layout.alignment: Qt.AlignVCenter
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
                Layout.alignment: Qt.AlignVCenter
                width: 62
                height: 62
                value: SystemStatsService.cpuUsage
                mainText: Math.round(SystemStatsService.cpuUsage * 100) + "%"
                subText: "CPU"
                progressColor: SystemStatsService.cpuUsage > 0.8 ? Theme.color1 : Theme.selected
                showSideText: false
            }

            CircularGauge {
                Layout.alignment: Qt.AlignVCenter
                width: 62
                height: 62
                value: SystemStatsService.ramUsage
                mainText: SystemStatsService.ramUsedText
                subText: "Memory"
                progressColor: Theme.color4
                showSideText: false
            }

            // Reserves space so the header row's own content doesn't
            // slide underneath the absolutely-positioned X below it.
            Item {
                Layout.preferredWidth: 28
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
            id: processListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.displayList
            spacing: 2

            // Tracks "is the pointer anywhere over the process list" —
            // drives the hover-freeze in _updateDisplayListLive above.
            // Coexists fine with each row's own HoverHandler below;
            // HoverHandlers (unlike TapHandlers) don't need exclusive
            // grabbing, every interested handler just gets notified.
            HoverHandler {
                id: listHoverHandler
            }

            delegate: Rectangle {
                id: row
                readonly property bool isHovered: rowHover.hovered
                readonly property bool isExpanded: !!root.expandedGroups[modelData.name]
                readonly property bool hasMultiple: modelData.count > 1

                width: ListView.view.width
                // Grows to fit expanded child rows (18px each) when toggled open.
                height: 40 + (isExpanded && hasMultiple ? modelData.count * 26 : 0)
                radius: 8
                color: isHovered ? Theme.backgroundAlt : "transparent"
                clip: true
                // Behavior on color {
                //     AnimColor {
                //         type: Anim.FastEffects
                //     }
                // }
                Behavior on height {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                // Was DesktopEntries.heuristicLookup() directly, bypassing
                // the memoized DesktopEntryService wrapper — whose own
                // header comment literally names THIS component as one of
                // the reasons that cache exists. Since `model:
                // root.displayList` is a plain JS array reassigned wholesale
                // on every 3s poll tick, ListView likely recreates every
                // delegate each refresh — meaning every process's icon was
                // being re-looked-up from scratch every 3 seconds, with zero
                // cache benefit. Same fix for the icon path resolution below.
                readonly property string iconName: DesktopEntryService.lookup(modelData.name)?.icon ?? ""

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
                                source: row.iconName !== "" ? DesktopEntryService.resolveIconPath(row.iconName) : ""
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
                    id: rowHover
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

    // Same "X" convention we're adding to Docker/Settings too —
    // ShellState.closeResumableComponent() both closes the dashboard
    // AND forgets this as the backgrounded/resumable tool (see
    // ShellState.qml), unlike just closing the dashboard normally
    // which would leave the bar's "you left something open" indicator
    // still pointing here.
    //
    // Anchored directly to root's own corner (NOT a RowLayout child)
    // — a RowLayout item only ever sits where the row's content
    // naturally ends, which isn't necessarily root's actual top-right
    // corner. Absolute positioning guarantees it regardless of how
    // wide the header content ends up being.
    IconButton {
        anchors.top: parent.top
        anchors.right: parent.right
        icon: "x"
        size: 28
        iconSize: 13
        radius: Theme.radius
        normalColor: Theme.backgroundAlt
        hoverColor: Theme.color1
        tooltipText: "Close"
        onTapped: ShellState.closeResumableComponent()
    }
}
