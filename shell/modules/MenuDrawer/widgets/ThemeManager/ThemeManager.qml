import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs.core
import qs.services

Item {
    id: root
    anchors.fill: parent

    // Το μονοπάτι που βρίσκονται τα JSONs
    property string userHome: Quickshell.env("HOME")
    property string themesDir: ThemeService.themesDir

    // Κρατάμε ποιο θέμα έχουμε επιλέξει (για να του βάζουμε ένα checkmark)
    property string confirmedPath: ""

    // Μόλις ανοίξει, το ListView παίρνει focus για να δουλεύει το πληκτρολόγιο
    Component.onCompleted: themeList.forceActiveFocus()

    // Το Model που διαβάζει τα JSON (On-Demand Loading)
    QtObject {
        id: internal
        property var themeModel: FolderListModel {
            folder: root.themesDir
            nameFilters: ["*.json"] // Φιλτράρουμε ΜΟΝΟ τα json αρχεία!
            showDirs: false
            sortField: FolderListModel.Name
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // ── Header ────────────────────────────────────────────────
        Column {
            spacing: 2
            Text {
                text: "Color Themes"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 16
                font.bold: true
            }
            Text {
                text: internal.themeModel.count + " themes available"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 11
                opacity: 0.45
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.4
        }

        // ── Vertical Theme List ───────────────────────────────────
        ListView {
            id: themeList
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Vertical // ΚΑΘΕΤΗ λίστα!
            spacing: 8
            clip: true
            model: internal.themeModel
            boundsBehavior: Flickable.StopAtBounds
            focus: true
            activeFocusOnTab: true

            property bool keyboardNavigating: false

            Timer {
                id: keyboardLockTimer
                interval: 600
                onTriggered: themeList.keyboardNavigating = false
            }

            // Πλοήγηση με τα Πάνω/Κάτω βελάκια!
            Keys.onUpPressed: {
                keyboardNavigating = true;
                keyboardLockTimer.restart();
                decrementCurrentIndex();
            }
            Keys.onDownPressed: {
                keyboardNavigating = true;
                keyboardLockTimer.restart();
                incrementCurrentIndex();
            }
            Keys.onReturnPressed: _confirmCurrent()
            Keys.onEnterPressed: _confirmCurrent()

            function _confirmCurrent() {
                if (currentItem && currentItem.itemPath) {
                    let path = currentItem.itemPath;
                    root.confirmedPath = path;
                    // Καλούμε το Service μας!
                    ThemeService.setColors(path, "dark");
                }
            }

            // ── Delegate (Κάθε Στοιχείο της Λίστας) ───────────────
            delegate: Rectangle {
                id: delegateItem

                property string itemPath: model.filePath.replace("file://", "")
                property bool isHovered: mouseArea.containsMouse
                property bool isCurrent: themeList.currentIndex === index
                property bool isConfirmed: itemPath === root.confirmedPath

                width: ListView.view.width
                height: 55 // Σταθερό ύψος σαν κουμπί μενού
                radius: Theme.radius

                // Δυναμικό Χρώμα Background
                color: isConfirmed ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15) : (isHovered || isCurrent ? Theme.backgroundAlt : "transparent")

                // Δυναμικό Border
                border.width: 1
                border.color: isConfirmed ? Theme.selected : (isHovered || isCurrent ? Theme.borderColor : "transparent")

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
                Behavior on border.color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 15

                    // Ένα μικρό εικονίδιο / κουκκίδα μπροστά
                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: isConfirmed ? Theme.selected : Theme.foreground
                        opacity: isConfirmed ? 1.0 : (isHovered || isCurrent ? 0.6 : 0.3)
                    }

                    // Το όνομα του αρχείου
                    Text {
                        Layout.fillWidth: true
                        text: {
                            // Καθαρίζουμε το ".json" για να φαίνεται ωραίο
                            let parts = (model.fileName || "").split(".");
                            parts.pop();
                            return parts.join(".");
                        }
                        color: isConfirmed ? Theme.selected : Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 15
                        font.bold: isConfirmed || isHovered || isCurrent
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Το Checkmark αν το έχουμε επιλέξει
                    Text {
                        visible: isConfirmed
                        text: "✓"
                        color: Theme.selected
                        font.pixelSize: 16
                        font.bold: true
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        if (themeList.keyboardNavigating)
                            return;
                        themeList.currentIndex = index;
                    }

                    onClicked: {
                        themeList._confirmCurrent();
                    }
                }
            }
        }
    }

    // ── Empty State ───────────────────────────────────────────────
    Text {
        anchors.centerIn: parent
        visible: internal.themeModel.count === 0
        text: "No themes found in\n~/.config/nisfere/themes/"
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 13
        opacity: 0.45
        horizontalAlignment: Text.AlignHCenter
    }
}
