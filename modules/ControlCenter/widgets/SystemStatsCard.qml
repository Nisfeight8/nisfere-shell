import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

GlassCard {
    Layout.fillWidth: true
    implicitHeight: statsRow.implicitHeight + 30

    RowLayout {
        id: statsRow

        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // --- 1. CPU ---
        CircularGauge {
            mainText: SystemStatsService.cpuTempText
            progressColor: Theme.selected
            sideTextSubtitle: "Usage"
            sideTextTitle: Math.round(SystemStatsService.cpuUsage * 100) + "%"
            subText: "CPU"
            trackColor: Theme.background
            value: SystemStatsService.cpuUsage
        }

        // --- 2. RAM ---
        CircularGauge {
            mainText: SystemStatsService.ramUsedText
            progressColor: Theme.selected
            sideTextSubtitle: "of " + SystemStatsService.ramTotalText
            sideTextTitle: Math.round(SystemStatsService.ramUsage * 100) + "%"
            subText: "Memory"
            trackColor: Theme.background
            value: SystemStatsService.ramUsage
        }

        // --- 3. DISK ---
        CircularGauge {
            mainText: SystemStatsService.diskUsedText
            progressColor: Theme.selected
            sideTextSubtitle: "of " + SystemStatsService.diskTotalText
            sideTextTitle: SystemStatsService.diskUsage
            subText: "Disk"
            trackColor: Theme.background
            value: parseInt(SystemStatsService.diskUsage) / 100
        }
    }
}
