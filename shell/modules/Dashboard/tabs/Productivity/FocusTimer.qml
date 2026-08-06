import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root
    anchors.fill: parent
    // Was missing entirely (and this file was also the only tab
    // without `id: root` at all) — same fix as the rest of the
    // Dashboard tabs: bottom-up from mainColumn's own implicit size.
    implicitWidth: mainColumn.implicitWidth
    implicitHeight: mainColumn.implicitHeight

    ColumnLayout {
        id: mainColumn
        anchors.centerIn: parent
        spacing: 26

        // ── Mode toggle ───────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Repeater {
                model: [
                    {
                        key: "focus",
                        label: "Focus",
                        icon: "brain"
                    },
                    {
                        key: "break",
                        label: "Break",
                        icon: "coffee"
                    },
                ]
                NavTile {
                    id: modeBtn
                    isActive: FocusService.mode === modelData.key
                    Layout.fillWidth: true
                    icon: modelData.icon
                    label: modelData.label
                    onTapped: FocusService.switchMode(modelData.key)
                }
            }
        }

        // ── Ring + duration adjust ────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            IconButton {
                icon: "minus"
                size: 46
                iconSize: 18
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                enabled: !FocusService.running
                tooltipText: "-" + (FocusService.stepSeconds / 60) + " min"
                onTapped: FocusService.decreaseDuration()
            }

            ColumnLayout {
                spacing: 6
                CircularGauge {
                    Layout.alignment: Qt.AlignHCenter
                    width: 220
                    height: 220
                    value: FocusService.progress
                    mainText: FocusService.formatTime()
                    subText: FocusService.mode === "focus" ? "Focus" : "Break"
                    progressColor: FocusService.mode === "focus" ? Theme.selected : Theme.color2
                    showSideText: false
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: FocusService.formatDuration() + " session"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    opacity: 0.5
                }
            }

            IconButton {
                icon: "plus"
                size: 46
                iconSize: 18
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                enabled: !FocusService.running
                tooltipText: "+" + (FocusService.stepSeconds / 60) + " min"
                onTapped: FocusService.increaseDuration()
            }
        }

        // ── Controls ──────────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            IconButton {
                icon: "rotate-ccw"
                size: 44
                iconSize: 18
                activeSolid: true
                radius: Theme.radius
                normalColor: Theme.backgroundAlt
                tooltipText: "Reset"
                onTapped: FocusService.reset()
            }

            IconButton {
                icon: FocusService.running ? "pause" : "play"
                size: 60
                iconSize: 26
                activeSolid: true
                radius: Theme.radius
                normalColor: Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15)
                hoverColor: Theme.selected
                activeColor: Theme.selected
                isActive: FocusService.running
                tooltipText: FocusService.running ? "Pause" : "Start"
                onTapped: FocusService.toggle()
            }
        }
    }
}
