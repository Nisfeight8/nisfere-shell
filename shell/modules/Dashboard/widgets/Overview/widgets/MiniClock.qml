import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.core
import qs.services

GlassCard {
    id: miniClockCard

    readonly property int cardMargin: 15
    implicitWidth: mainLayout.implicitWidth + mainLayout.anchors.margins * 2
    implicitHeight: mainLayout.implicitHeight + mainLayout.anchors.margins * 2
    
    anchors.fill: parent

    SystemClock {
        id: sysClock

        precision: SystemClock.Seconds
    }
    ColumnLayout {
        id: mainLayout

        // 3. Create a dynamic reference size based on actual width/height for text scaling
        property real refSize: 250
        // 2. Fill the card safely with margins
        anchors.fill: parent
        anchors.margins: miniClockCard.cardMargin
        spacing: 10

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.selected
                font.bold: true
                font.family: Theme.fontName
                // Scale main time dynamically
                font.pixelSize: Math.max(20, mainLayout.refSize * 0.20)
                text: Qt.formatDateTime(sysClock.date, "hh:mm")
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: Math.max(12, mainLayout.refSize * 0.06)
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
                    font.pixelSize: Math.max(12, mainLayout.refSize * 0.05)
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
                    font.pixelSize: Math.max(12, mainLayout.refSize * 0.06)
                    horizontalAlignment: Text.AlignHCenter
                    text: monthGrid.title
                }
                Text {
                    color: nextMouse.containsMouse ? Theme.selected : Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(12, mainLayout.refSize * 0.05)
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
                // Ensure this row doesn't eat up the space needed by the grid
                Layout.preferredHeight: Math.max(15, mainLayout.refSize * 0.08)
                locale: monthGrid.locale

                delegate: Text {
                    required property string shortName

                    color: Theme.foreground
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: Math.max(10, mainLayout.refSize * 0.045)
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

                Layout.fillHeight: true

                // 4. CRITICAL FIX: Tell the grid to stretch dynamically!
                // It will automatically divide this space by 7 columns and 6 rows.
                Layout.fillWidth: true

                delegate: Item {
                    required property var model

                    Rectangle {
                        // Dynamically scale the hover/selected circles based on the cell's actual size
                        property real circleSize: Math.min(parent.width, parent.height) * 0.8

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
                        // Scale day numbers based on their cell height
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

                Component.onCompleted: {
                    month = sysClock.date.getMonth();
                    year = sysClock.date.getFullYear();
                }
            }
        }
    }
}
