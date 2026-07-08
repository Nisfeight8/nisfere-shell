import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    function _statColor(usage) {
        if (usage > 0.8)
            return Theme.color1;
        if (usage > 0.5)
            return Theme.color3;
        return Theme.color2;
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 12

        // ── Circular gauges ───────────────────────────────────────
        // Explicit height on wrapper item — prevents gauges rendering
        // at height:0 and disappearing behind subsequent elements
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: [
                    {
                        value: SystemStatsService.cpuUsage,
                        main: (SystemStatsService.cpuUsage * 100).toFixed(0) + "%",
                        sub: "CPU",
                        sideTop: SystemStatsService.cpuTempText,
                        sideSub: "temp"
                    },
                    {
                        value: SystemStatsService.ramUsage,
                        main: SystemStatsService.ramUsedText,
                        sub: "RAM",
                        sideTop: (SystemStatsService.ramUsage * 100).toFixed(0) + "%",
                        sideSub: SystemStatsService.ramTotalText
                    },
                    {
                        value: parseFloat(SystemStatsService.diskUsage) / 100,
                        main: SystemStatsService.diskUsedText,
                        sub: "DISK",
                        sideTop: SystemStatsService.diskUsage,
                        sideSub: SystemStatsService.diskTotalText
                    },
                ]

                // ↓ Explicit height — critical! Without it RowLayout
                //   gives height:0 and the gauge renders behind siblings
                Item {
                    Layout.fillWidth: true
                    height: 140

                    CircularGauge {
                        anchors.centerIn: parent
                        width: 130
                        height: 130
                        value: modelData.value
                        mainText: modelData.main
                        subText: modelData.sub
                        sideTextTitle: modelData.sideTop
                        sideTextSubtitle: modelData.sideSub
                        progressColor: root._statColor(modelData.value)
                    }
                }
            }
        }

        // ── Network speed ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: 8
            color: Theme.backgroundAlt

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    LucideIcon {
                        icon: "arrow-down-to-line"
                        size: 13
                        color: Theme.color2
                    }
                    Text {
                        text: SystemStatsService.netDownText
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    width: 1
                    height: 14
                    color: Theme.borderColor
                    opacity: 0.4
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    spacing: 6
                    LucideIcon {
                        icon: "arrow-up-from-line"
                        size: 13
                        color: Theme.color4
                    }
                    Text {
                        text: SystemStatsService.netUpText
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
