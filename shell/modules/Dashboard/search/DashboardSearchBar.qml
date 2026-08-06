import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

// Search bar row for SearchComponent — search field (left, fills) +
// active-provider icon (right, opens ProviderPicker). No left-side
// user/back icon anymore: there's no "back" concept since editing the
// text itself is how you exit a drilldown (see onTextChanged below —
// today that's just "providerPicker", since docker/sysmon/settings/
// appLauncherFull are top-level Dashboard components now, not nested
// panels reached from here), and no "user" icon — Escape now always
// closes the whole Dashboard, so no separate "exit search, stay on
// tabs" affordance is needed either.
Item {
    id: root

    implicitHeight: 40

    signal keyPressed(var event)
    signal accepted
    signal escapePressed

    readonly property alias text: searchBar.text
    readonly property alias input: searchBar.input

    readonly property var activeProvider: SearchProviders.findById(ShellState.dashboardSearchProviderId)

    // Whether the ProviderPicker panel is the current search drilldown
    // — drives providerBtn's active-look below and lets tapping the
    // button toggle it the same way it used to toggle the old Popup's
    // open/close.
    readonly property bool _pickerPanelOpen: ShellState.dashboardSearchDrilldownPanelId === "providerPicker"

    RowLayout {
        anchors.fill: parent
        spacing: 8

        SearchBar {
            id: searchBar
            Layout.fillWidth: true
            placeholderText: placeholderCycle.currentText

            // Guards the sync loop: true only while THIS code is
            // writing to `text` because ShellState changed externally
            // (drilldown-open reset, provider-picker selection via
            // ShellState, etc.) — NOT while the user is actually
            // typing. Without this, every external/programmatic text
            // reset would also incorrectly clear any open drilldown
            // (see onTextChanged below) and would re-forward into
            // ShellState redundantly.
            property bool _isSyncingFromState: false

            Component.onCompleted: {
                _isSyncingFromState = true;
                text = ShellState.dashboardSearchText;
                _isSyncingFromState = false;
                // Unconditional now — this component only ever exists
                // while ShellState.dashboardActiveComponent === "search"
                // in the first place (DashboardContent's AnimLoader
                // tears the whole SearchComponent down otherwise), so
                // "is search active" was always true by the time this
                // runs. The old check also OR'd in "text !== ''", which
                // is now redundant for the same reason.
                input.forceActiveFocus();
            }

            onTextChanged: {
                if (_isSyncingFromState)
                    return;

                // Auto-insert a space right after a fully-typed keyword
                // (e.g. "@tools" -> "@tools ") so typing can continue
                // immediately. Exact match only, no trailing space yet.
                const exactKeywordMatch = SearchProviders.keywordProviders.find(p => p.keyword === text);
                if (exactKeywordMatch) {
                    text = text + " ";
                    input.cursorPosition = text.length;
                    return; // re-enters onTextChanged, still not syncing, falls through below
                }

                // No back button anymore — editing the query IS how you
                // exit a drilldown (providerPicker today; a future git/
                // ssh repo-browser view later) back to the results list
                // underneath it.
                if (ShellState.dashboardSearchHasDrilldown)
                    ShellState.closeSearchDrilldown();

                ShellState.dashboardSearchText = text;
            }

            Connections {
                target: ShellState
                function onDashboardSearchTextChanged() {
                    if (searchBar.text !== ShellState.dashboardSearchText) {
                        searchBar._isSyncingFromState = true;
                        searchBar.text = ShellState.dashboardSearchText;
                        searchBar._isSyncingFromState = false;
                    }
                }
                // Previous onDashboardSearchCompActiveChanged handler
                // (re-grabbing focus when search became active) removed
                // — dead code, same reasoning as Component.onCompleted
                // above: this exact instance can never observe that
                // transition, since entering "search" always creates a
                // brand new instance of this whole file.
            }

            onKeyPressed: e => {
                if (e.key === Qt.Key_Escape) {
                    root.escapePressed();
                    e.accepted = true;
                    return;
                }
                if (e.key === Qt.Key_Backspace) {
                    const kw = SearchProviders.keywordProviders.find(p => text === p.keyword + " ");
                    if (kw) {
                        text = "";
                        e.accepted = true;
                        return;
                    }
                }
                if (e.key === Qt.Key_Left && input.cursorPosition !== 0)
                    return;
                if (e.key === Qt.Key_Right && input.cursorPosition !== text.length)
                    return;
                root.keyPressed(e);
            }
            onAccepted: root.accepted()
        }

        Rectangle {
            id: providerBtn
            width: 40
            height: 40
            radius: Theme.radius
            color: pickerHover.hovered || root._pickerPanelOpen ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15) : Theme.backgroundAlt
            border.width: 1
            border.color: Theme.borderColor
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            LucideIcon {
                anchors.centerIn: parent
                icon: root.activeProvider ? root.activeProvider.icon : "layout-grid"
                size: 17
                color: root._pickerPanelOpen ? Theme.selected : Theme.foreground
            }
            HoverHandler {
                id: pickerHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: {
                    if (root._pickerPanelOpen)
                        ShellState.closeSearchDrilldown();
                    else
                        ShellState.openSearchDrilldown("providerPicker", ShellState.dashboardSearchProviderId);
                }
            }
        }
    }

    Item {
        id: placeholderCycle
        property var texts: ["Search apps..."].concat(SearchProviders.keywordProviders.map(p => "Try \"" + p.keyword + "\" for " + p.label.toLowerCase() + "..."))
        property int idx: 0
        readonly property string currentText: searchBar.text === "" ? texts[idx] : ""

        Timer {
            interval: 2500
            running: searchBar.text === ""
            repeat: true
            onTriggered: placeholderCycle.idx = (placeholderCycle.idx + 1) % placeholderCycle.texts.length
        }
    }
}
