pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.core
import "widgets"

Item {
    id: root

    property int _readyCount: 0
    readonly property bool _allReady: _readyCount >= 4
    // Height genuinely matters — see TabsComponent's tabsLoader,
    // which only sets Layout.fillWidth (not fillHeight), so this tab's
    // height is read bottom-up from here and becomes the Dashboard
    // panel's real height while this tab is active.
    //
    // Width deliberately has NO opinion here (unlike height above):
    // this tab's whole internal layout is fillWidth-based already, so
    // it adapts to whatever width it's given rather than needing to
    // request one. It used to declare `implicitWidth: 800`, which —
    // via that same tabsLoader — bubbled up into TabsComponent's own
    // implicitWidth and made the ENTIRE drawer panel jump to ~800px
    // wide specifically while this tab was open, then shrink back to
    // TabsComponent's minContentWidth floor on other tabs. Exactly the
    // resize-jump problem minContentWidth/minContentHeight were meant
    // to prevent, just on the other axis.
    implicitHeight: 420
    implicitWidth: Screen.width /2.5
    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 10
        // Was tracked (_readyCount/_allReady) but never used — the 4
        // Loaders below are asynchronous, so without this they'd each
        // pop in individually whenever they happen to finish, at
        // slightly different times. Fading the whole grid in together
        // once ALL 4 are ready reads as one clean reveal instead.
        opacity: root._allReady ? 1 : 0
        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        ColumnLayout {
            id: leftColumn
            Layout.fillHeight: true
            Layout.fillWidth: true
            // Explicit ratio unit — NOT derived from any child's
            // implicit width. Both columns' actual widths come purely
            // from how RowLayout splits available space between these
            // two ratios (1 : rightColumnWidthRatio below), same as
            // the reasoning behind MiniClock's `refSize` fix: internal
            // content size should never leak into deciding how much
            // space a column gets — it should be the other way round.
            Layout.preferredWidth: 1

            Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                asynchronous: true
                sourceComponent: Component {
                    MiniClock {}
                }
                onLoaded: root._readyCount++
            }
        }
        ColumnLayout {
            id: rightColumn
            Layout.fillHeight: true
            Layout.fillWidth: true
            // Same ratio unit as leftColumn's Layout.preferredWidth: 1
            // above — this column is deliberately
            // rightColumnWidthRatio times as wide as the left one,
            // regardless of what MiniWeather/MiniMedia/
            // SystemInfoDetails' own natural sizes happen to be.
            property real rightColumnWidthRatio: 1.1
            Layout.preferredWidth: rightColumnWidthRatio
            spacing: 10

            // All three stacked below get the SAME explicit
            // Layout.preferredHeight ratio unit (1 each = equal
            // thirds) — same reasoning as leftColumn/rightColumn's
            // width split: MiniWeather/MiniMedia/SystemInfoDetails
            // have genuinely different natural content heights, so
            // without this they'd get an uneven, incidental vertical
            // split instead of a deliberate one. Tune these three
            // numbers directly if you want e.g. MiniMedia taller than
            // the other two (say 1.3 instead of 1).
            Loader {
                asynchronous: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 1
                sourceComponent: Component {
                    MiniWeather {}
                }
                onLoaded: root._readyCount++
            }
            Loader {
                asynchronous: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 1
                sourceComponent: Component {
                    MiniMedia {}
                }
                onLoaded: root._readyCount++
            }
            Loader {
                asynchronous: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 1
                sourceComponent: Component {
                    SystemInfoDetails {}
                }
                onLoaded: root._readyCount++
            }
        }
    }
}
