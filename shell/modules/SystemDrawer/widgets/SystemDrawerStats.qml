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
        // Was a Repeater over an inline array literal that referenced
        // SystemStatsService.* directly — since that array expression
        // re-evaluates (producing a brand-new array object) every
        // time ANY of those stats changes, Repeater treated it as "the
        // model changed" and destroyed+recreated all 3 delegates on
        // every stats refresh tick. That meant CircularGauge's own
        // skip-reveal-on-mount fix (see core/CircularGauge.qml) kicked
        // in on every single tick too, since each recreation looked
        // like a fresh mount — so these gauges likely never actually
        // animated a value change smoothly, just silently snapped.
        // Unrolled into 3 explicit gauges instead (same approach
        // Weather.qml already uses for its own small fixed set of
        // cards) — each one's own bindings stay reactive normally,
        // with nothing ever recreating the Item/CircularGauge itself.
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            // Explicit height on wrapper item — prevents gauges rendering
            // at height:0 and disappearing behind subsequent elements
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 140
                height: 140

                CircularGauge {
                    anchors.centerIn: parent
                    width: 130
                    height: 130
                    value: SystemStatsService.cpuUsage
                    mainText: SystemStatsService.cpuTempText
                    subText: "CPU"
                    sideTextTitle: Math.round(SystemStatsService.cpuUsage * 100) + "%"
                    sideTextSubtitle: "Usage"
                    progressColor: root._statColor(SystemStatsService.cpuUsage)
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 140
                height: 140

                CircularGauge {
                    anchors.centerIn: parent
                    width: 130
                    height: 130
                    value: SystemStatsService.ramUsage
                    mainText: SystemStatsService.ramUsedText
                    subText: "RAM"
                    sideTextTitle: (SystemStatsService.ramUsage * 100).toFixed(0) + "%"
                    sideTextSubtitle: SystemStatsService.ramTotalText
                    progressColor: root._statColor(SystemStatsService.ramUsage)
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 140
                height: 140

                CircularGauge {
                    anchors.centerIn: parent
                    width: 130
                    height: 130
                    value: parseFloat(SystemStatsService.diskUsage) / 100
                    mainText: SystemStatsService.diskUsedText
                    subText: "DISK"
                    sideTextTitle: SystemStatsService.diskUsage
                    sideTextSubtitle: SystemStatsService.diskTotalText
                    progressColor: root._statColor(parseFloat(SystemStatsService.diskUsage) / 100)
                }
            }
        }

        // ── Network speed ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: Theme.radius
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
