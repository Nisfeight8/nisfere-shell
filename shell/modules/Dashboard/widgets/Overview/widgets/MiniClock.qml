import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.core
import qs.services

GlassCard {
    id: miniClockCard
    implicitWidth: mainLayout.implicitWidth + mainLayout.anchors.margins * 2
    implicitHeight: mainLayout.implicitHeight + mainLayout.anchors.margins * 2

    readonly property real cellSize: 40

    SystemClock {
        id: sysClock
        precision: SystemClock.Seconds
    }

    ColumnLayout {
        id: mainLayout
        property real refSize: 120

        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter

            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.selected
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: Math.max(24, mainLayout.refSize * 0.45)
                text: Qt.formatDateTime(sysClock.date, "hh:mm")
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: Math.max(15, mainLayout.refSize * 0.045)
                opacity: 0.6
                text: Qt.formatDateTime(sysClock.date, "dddd, d MMMM")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.foreground
            opacity: 0.1
        }

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 5

            RowLayout {
                Layout.fillWidth: true

                Text {
                    color: prevMouse.containsMouse ? Theme.selected : Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(12, mainLayout.refSize * 0.045)
                    opacity: prevMouse.containsMouse ? 1 : 0.5
                    text: ""

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: monthGrid.previousMonth()
                    }
                }
                Text {
                    Layout.fillWidth: true
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(13, mainLayout.refSize * 0.05)
                    horizontalAlignment: Text.AlignHCenter
                    text: monthGrid.title
                }
                Text {
                    color: nextMouse.containsMouse ? Theme.selected : Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(12, mainLayout.refSize * 0.045)
                    opacity: nextMouse.containsMouse ? 1 : 0.5
                    text: ""

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: monthGrid.nextMonth()
                    }
                }
            }

            DayOfWeekRow {
                Layout.fillWidth: true
                locale: monthGrid.locale

                delegate: Text {
                    required property string shortName
                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(10, mainLayout.refSize * 0.035)
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.4
                    text: shortName
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MonthGrid {
                id: monthGrid

                function nextMonth() {
                    if (month === 11) {
                        year++;
                        month = 0;
                    } else
                        month++;
                }
                function previousMonth() {
                    if (month === 0) {
                        year--;
                        month = 11;
                    } else
                        month--;
                }

                Layout.preferredWidth: miniClockCard.cellSize * 8
                Layout.preferredHeight: miniClockCard.cellSize * 5
                month: sysClock.date.getMonth()
                year: sysClock.date.getFullYear()

                delegate: Item {
                    required property var model

                    Rectangle {
                        property real circleSize: Math.min(parent.width, parent.height) * 0.75
                        anchors.centerIn: parent
                        color: model.today ? Theme.selected : (dayMouseArea.containsMouse ? Theme.foreground : "transparent")
                        height: circleSize
                        radius: circleSize / 2
                        width: circleSize

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 100
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        color: model.today ? Theme.background : (dayMouseArea.containsMouse ? Theme.background : Theme.foreground)
                        font.bold: model.today
                        font.family: Theme.fontName
                        font.pixelSize: Math.max(10, parent.height * 0.4)
                        opacity: model.month === monthGrid.month ? 1 : 0.25
                        text: model.day
                    }
                    MouseArea {
                        id: dayMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                    }
                }
            }
        }
    }
}
