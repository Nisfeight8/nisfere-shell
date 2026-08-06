import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "../search"

Item {
    id: root
    property int spacing: 10
    property string searchText: ""
    property bool loading: true
    property string activeMode: Colors.mode

    readonly property var filteredThemes: {
        const q = root.searchText.toLowerCase();
        return q === "" ? ThemeActions.themes : ThemeActions.themes.filter(t => t.name.toLowerCase().includes(q));
    }

    readonly property var results: root.filteredThemes.map(t => ({
                id: t.name,
                title: t.name,
                subtitle: (Colors.sourceType === "static" && Colors.sourceName === t.name) ? "Active · " + Colors.mode : "",
                icon: "palette",
                confirmed: Colors.sourceType === "static" && Colors.sourceName === t.name,
                swatches: ["color1", "color2", "color3", "color4", "color5"].map(k => t.colors?.[k] ?? Theme.borderColor)
            }))

    function navigate(delta) {
        resultsList.navigate(delta);
    }
    function activateSelected() {
        resultsList.activateSelected();
    }

    Component.onCompleted: ThemeActions.fetchThemes()

    Connections {
        target: ThemeActions
        function onThemesLoaded() {
            root.loading = false;
        }
    }

    // Bottom-up from headerRow + resultsList's own implicit heights —
    // resultsList (ResultsListView) already handles its own stable
    // sizing internally (real contentHeight, bootstrap fallback,
    // empty/loading state), nothing to reimplement here.
    implicitWidth: 640
    implicitHeight: headerRow.implicitHeight + resultsList.implicitHeight + 10

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: root.spacing

        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 10

            Column {
                spacing: 2
                Text {
                    text: "Color Themes"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    font.bold: true
                }
                Text {
                    text: root.loading ? "Loading..." : root.results.length + " themes available"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    opacity: 0.45
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "Light"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12
                opacity: root.activeMode === "light" ? 1.0 : 0.4
            }
            ToggleSwitch {
                checked: root.activeMode === "dark"
                onToggled: root.activeMode = root.activeMode === "dark" ? "light" : "dark"
            }
            Text {
                text: "Dark"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12
                opacity: root.activeMode === "dark" ? 1.0 : 0.4
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.4
        }

        // Layout.preferredHeight (not fillHeight) + AlignTop — prevents
        // the "empty gap below a couple of results" bug, same reasoning
        // as AppLauncherPanel's list area. resultsList.implicitHeight
        // is ResultsListView's own bottom-up value (real contentHeight
        // internally, capped/floored) — read directly instead of
        // recomputing it here.
        ResultsListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            Layout.alignment: Qt.AlignTop
            results: root.results
            loading: root.loading
            loadingText: "Loading themes..."
            emptyText: "No matching themes"
            maxListHeight: 800
            onResultActivated: (r, index) => {
                const t = root.filteredThemes[index];
                if (t)
                    ThemeActions.setColors(t.name, root.activeMode);
            }
        }
    }
}
