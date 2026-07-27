import QtQuick
import QtQuick.Layouts
import qs.core

// Icon+title header, optional sparkline, then arbitrary detail rows
// below — the "Network card" style, generalized so CPU/RAM/Network all
// share one consistent look instead of mixing donut gauges with charts.
// Usage:
//   StatChartCard {
//       icon: "cpu"; title: "CPU"; accentColor: Theme.selected
//       chartValues: SystemStatsService.cpuHistory
//
//       RowLayout {
//           Layout.fillWidth: true
//           Text { Layout.fillWidth: true; text: "Usage" }
//           Text { text: "42%" }
//       }
//   }
ColumnLayout {
    id: root

    property string icon: ""
    property string title: ""
    property color accentColor: Theme.selected
    property var chartValues: null   // null = no chart (e.g. Disk, which barely changes)
    property real chartHeight: 40

    // Detail rows declared inside StatChartCard{} land here, below the chart
    default property alias rows: rowsColumn.data

    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        LucideIcon {
            icon: root.icon
            size: 15
            color: root.accentColor
        }
        Text {
            Layout.fillWidth: true
            text: root.title
            color: Theme.foreground
            font.family: Theme.fontName
            font.pixelSize: 15
            font.bold: true
        }
    }

    Sparkline {
        Layout.fillWidth: true
        Layout.preferredHeight: root.chartHeight
        visible: root.chartValues !== null
        values: root.chartValues ?? []
        lineColor: root.accentColor
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.borderColor
        opacity: 0.3
        visible: root.chartValues !== null
    }

    ColumnLayout {
        id: rowsColumn
        Layout.fillWidth: true
        spacing: 4
    }
}
