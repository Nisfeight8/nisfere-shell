import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"

Item {
    id: root
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    function _statColor(usage) {
        if (usage > 0.8)
            return Theme.color1;
        if (usage > 0.5)
            return Theme.color3;
        return Theme.color2;
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 16

        // ── 1. OVERVIEW GAUGES ───────────────────
        GlassCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 160

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    CircularGauge {
                        anchors.centerIn: parent
                        width: 120
                        height: 120
                        value: SystemStatsService.cpuUsage
                        mainText: SystemStatsService.cpuTempText
                        subText: "CPU"
                        sideTextTitle: Math.round(SystemStatsService.cpuUsage * 100) + "%"
                        sideTextSubtitle: "Usage"
                        trackColor: Theme.background
                        progressColor: root._statColor(SystemStatsService.cpuUsage)
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    CircularGauge {
                        anchors.centerIn: parent
                        width: 120
                        height: 120
                        value: SystemStatsService.ramUsage
                        mainText: SystemStatsService.ramUsedText
                        subText: "RAM"
                        sideTextTitle: (SystemStatsService.ramUsage * 100).toFixed(0) + "%"
                        sideTextSubtitle: SystemStatsService.ramTotalText
                        trackColor: Theme.background
                        progressColor: root._statColor(SystemStatsService.ramUsage)
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    CircularGauge {
                        anchors.centerIn: parent
                        width: 120
                        height: 120
                        value: parseFloat(SystemStatsService.diskUsage) / 100
                        mainText: SystemStatsService.diskUsedText
                        subText: "DISK"
                        sideTextTitle: SystemStatsService.diskUsage
                        sideTextSubtitle: SystemStatsService.diskTotalText
                        trackColor: Theme.background
                        progressColor: root._statColor(parseFloat(SystemStatsService.diskUsage) / 100)
                    }
                }
            }
        }

        // ── 2. DETAILED CARDS  ────────────


        // -- CPU CARD --
        StatChartCard {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            icon: "cpu"
            title: "CPU History"
            accentColor: SystemStatsService.cpuUsage > 0.8 ? Theme.color1 : Theme.selected
            chartValues: SystemStatsService.cpuHistory

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Usage"
                    color: Theme.foreground
                    font.pixelSize: 12
                    opacity: 0.75
                }
                Text {
                    text: Math.round(SystemStatsService.cpuUsage * 100) + "%"
                    color: Theme.foreground
                    font.pixelSize: 12
                    font.bold: true
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Temperature"
                    color: Theme.foreground
                    font.pixelSize: 12
                    opacity: 0.75
                }
                Text {
                    text: SystemStatsService.cpuTempText
                    color: Theme.foreground
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        // -- RAM CARD --
        StatChartCard {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            icon: "memory-stick"
            title: "Memory"
            accentColor: Theme.color2
            chartValues: SystemStatsService.ramHistory

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Used"
                    color: Theme.foreground
                    font.pixelSize: 12
                    opacity: 0.75
                }
                Text {
                    text: SystemStatsService.ramUsedText
                    color: Theme.foreground
                    font.pixelSize: 12
                    font.bold: true
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Total"
                    color: Theme.foreground
                    font.pixelSize: 12
                    opacity: 0.75
                }
                Text {
                    text: SystemStatsService.ramTotalText
                    color: Theme.foreground
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        // -- NETWORK CARD --
        StatChartCard {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            icon: "arrow-up-down"
            title: "Network"
            accentColor: Theme.color5
            chartValues: SystemStatsService.netHistory

            RowLayout {
                Layout.fillWidth: true
                LucideIcon {
                    icon: "arrow-down"
                    size: 12
                    color: Theme.color2
                }
                Text {
                    Layout.fillWidth: true
                    text: "Download"
                    color: Theme.foreground
                    font.pixelSize: 12
                    opacity: 0.75
                }
                Text {
                    text: SystemStatsService.netDownText
                    color: Theme.foreground
                    font.pixelSize: 12
                    font.bold: true
                }
            }
            RowLayout {
                Layout.fillWidth: true
                LucideIcon {
                    icon: "arrow-up"
                    size: 12
                    color: Theme.color4
                }
                Text {
                    Layout.fillWidth: true
                    text: "Upload"
                    color: Theme.foreground
                    font.pixelSize: 12
                    opacity: 0.75
                }
                Text {
                    text: SystemStatsService.netUpText
                    color: Theme.foreground
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        // ── 3. BOTTOM BUTTON (Full System Monitor) ──────────────────
        NavTile {
            Layout.fillWidth: true
            Layout.topMargin: 8
            icon: "activity"
            label: "Full System Monitor"
            onTapped: {
                ShellState.appLauncherOpened = true;
                ShellState.launcherActiveTab = 1;
                ShellState.launcherActiveTool = "sysmon";
                ShellState.systemDrawerOpened = false; // Κλείνουμε το drawer
            }
        }
    }
}
