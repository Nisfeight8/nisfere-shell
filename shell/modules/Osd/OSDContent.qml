import QtQuick
import QtQuick.Layouts
import qs.core

// The OSD's visual card content — extracted from OSD.qml so it can be
// loaded via BaseDrawer's contentComponent (BaseDrawer now IS the OSD
// window; see OSD.qml). Pure presentation, no service/state logic here.
Item {
    id: content

    required property string osdIconName
    required property string osdTitleText
    required property string osdSubtitleText
    required property real osdValueNum
    required property bool osdMutedFlag
    required property bool showBarFlag
    required property bool showCountdownFlag

    implicitWidth: 260
    implicitHeight: contentColumn.implicitHeight + 32

    // Subtle top highlight — signature detail, not a full shadow system.
    // Left/right margins match Theme.radius (not just 1px) so this
    // flat-cornered line clears the PARENT's rounded corner curve —
    // with only 1px margins, its square corners poked out past the
    // rounding, since clip:true only clips to the rectangular bounds,
    // not the rounded shape itself.
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 1
            leftMargin: Theme.radius
            rightMargin: Theme.radius
        }
        height: 1
        radius: 1
        color: Theme.foreground
        opacity: 0.06
    }

    RowLayout {
        id: contentColumn
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 14

        // ── Icon badge (or countdown number) ──────────────────────────
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 42
            height: 42
            radius: width / 2
            color: Theme.backgroundAlt
            border.color: Theme.borderColor
            border.width: Theme.widgetBorderWidth
            // No Behavior on width/height here — fixed 42x42, never
            // actually changes, so there was nothing for one to do
            // (removed a pair of dead commented-out ones that used to
            // sit here).

            LucideIcon {
                anchors.centerIn: parent
                icon: content.osdIconName
                size: 20
                color: content.osdMutedFlag ? Theme.foreground : Theme.selected
                opacity: content.osdMutedFlag ? 0.5 : 1.0
                visible: !content.showCountdownFlag
            }

            Text {
                anchors.centerIn: parent
                visible: content.showCountdownFlag
                text: Math.round(content.osdValueNum)
                color: Theme.selected
                font.family: Theme.fontName
                font.pixelSize: 26
                font.bold: true
            }
        }

        // ── Title + bar / subtitle ─────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: content.osdTitleText
                    elide: Text.ElideRight
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.foreground
                }

                Text {
                    visible: content.showBarFlag
                    text: Math.round(content.osdValueNum * 100) + "%"
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    opacity: 0.6
                    color: Theme.foreground
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                visible: content.showBarFlag

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.foreground
                    opacity: 0.12
                }

                Rectangle {
                    id: barFill
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    radius: height / 2
                    color: content.osdMutedFlag ? Theme.foreground : Theme.selected
                    opacity: content.osdMutedFlag ? 0.35 : 1.0
                    width: Math.max(height, parent.width * (content.osdMutedFlag ? 0.0 : content.osdValueNum))

                    // Was commented-out raw NumberAnimation/ColorAnimation
                    // — enabled with the established Anim/AnimColor
                    // convention used everywhere else (e.g. BatteryCard's
                    // battery-bar fill is the same shape of animation).
                    Behavior on width {
                        Anim {
                            type: Anim.FastToggle
                        }
                    }
                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }
                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }

                    Rectangle {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        height: parent.height / 2
                        radius: parent.radius
                        color: Theme.foreground
                        opacity: 0.12
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !content.showBarFlag && content.osdSubtitleText !== ""
                text: content.osdSubtitleText
                elide: Text.ElideRight
                font.family: Theme.fontName
                font.pixelSize: 12
                opacity: 0.65
                color: Theme.foreground
            }
        }
    }
}
