import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.core
import qs.services

Item {
    id: root
    anchors.fill: parent

    property bool applyDynamicColors: true
    property string confirmedPath: DynamicColors.wallpaper
    property string previewPath: ""

    Component.onCompleted: wallpaperList.forceActiveFocus()

    // ── Debounce: preview μόνο αν ο χρήστης μείνει 250ms ─────────
    Timer {
        id: previewTimer
        interval: 250
        onTriggered: {
            if (root.previewPath !== "")
                WallpaperService.previewWallpaper(root.previewPath);
        }
    }

    // ── Restore: μικρό delay πριν επαναφορά ────────────────────────
    // Χωρίς delay, το gap μεταξύ items trigger-άρει restore συνέχεια
    Timer {
        id: restoreTimer
        interval: 150
        onTriggered: {
            if (root.previewPath === "" && root.confirmedPath !== "")
                WallpaperService.previewWallpaper(root.confirmedPath);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // ── Header ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Column {
                spacing: 2
                Text {
                    text: "Wallpapers"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    font.bold: true
                }
                Text {
                    text: WallpaperService.model.count + " found"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 10
                    opacity: 0.45
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "Dynamic colors"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12
                opacity: 0.7
                verticalAlignment: Text.AlignVCenter
            }

            // ── Custom Toggle ─────────────────────────────────────
            Rectangle {
                width: 44
                height: 24
                radius: 12
                color: root.applyDynamicColors ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.9) : Theme.backgroundAlt
                border.color: root.applyDynamicColors ? Theme.selected : Theme.borderColor
                border.width: 1

                Behavior on color {
                    ColorAnimation {
                        duration: 160
                    }
                }
                Behavior on border.color {
                    ColorAnimation {
                        duration: 160
                    }
                }

                // Thumb
                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.applyDynamicColors ? parent.width - width - 3 : 3
                    color: "white"
                    opacity: root.applyDynamicColors ? 1.0 : 0.55

                    Behavior on x {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.applyDynamicColors = !root.applyDynamicColors
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.4
        }

        // ── Horizontal Wallpaper List ─────────────────────────────
        ListView {
            id: wallpaperList
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            spacing: 10
            clip: true
            model: WallpaperService.model
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 200
            focus: true

            activeFocusOnTab: true
            property bool keyboardNavigating: false

            Timer {
                id: keyboardLockTimer
                interval: 600
                onTriggered: wallpaperList.keyboardNavigating = false
            }

            Keys.onLeftPressed: {
                keyboardNavigating = true;
                keyboardLockTimer.restart();
                decrementCurrentIndex();
            }
            Keys.onRightPressed: {
                keyboardNavigating = true;
                keyboardLockTimer.restart();
                incrementCurrentIndex();
            }
            Keys.onReturnPressed: _confirmCurrent()
            Keys.onEnterPressed: _confirmCurrent()

            // ── Preview on keyboard navigation ────────────────────
            // currentItem εκθέτει το itemPath του delegate
            onCurrentItemChanged: {
                if (currentItem && currentItem.itemPath) {
                    root.previewPath = currentItem.itemPath;
                    previewTimer.restart();
                    restoreTimer.stop();
                }
            }

            // ── Restore όταν φεύγει ο χρήστης από τη λίστα ───────
            HoverHandler {
                onHoveredChanged: {
                    if (!hovered) {
                        root.previewPath = "";
                        previewTimer.stop();
                        restoreTimer.start();
                    }
                }
            }

            function _confirmCurrent() {
                if (currentItem && currentItem.itemPath) {
                    let path = currentItem.itemPath;
                    root.confirmedPath = path;
                    root.previewPath = "";
                    previewTimer.stop();
                    WallpaperService.setWallpaper(path, root.applyDynamicColors);
                }
            }

            delegate: Item {
                id: delegateItem

                // ✅ Εκθέτουμε path ώστε το ListView.currentItem.itemPath να δουλεύει
                property string itemPath: model.filePath.replace("file://", "")
                property bool isHovered: mouseArea.containsMouse
                property bool isCurrent: wallpaperList.currentIndex === index
                property bool isConfirmed: itemPath === root.confirmedPath

                width: 300
                height: wallpaperList.height

                Rectangle {
                    id: card
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Theme.radius
                    color: "transparent"

                    border.width: isConfirmed ? 2 : (isHovered || isCurrent ? 2 : 1)
                    border.color: isConfirmed ? Theme.selected : (isHovered || isCurrent ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.5) : Theme.borderColor)

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                    Behavior on border.width {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    // ── Wallpaper image ────────────────────────────
                    Image {
                        id: sourceImage
                        anchors.fill: parent
                        anchors.margins: card.border.width
                        source: model.filePath
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                        scale: (isHovered || isCurrent) ? 1.04 : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        id: imgMask
                        anchors.fill: sourceImage
                        radius: Theme.radius - card.border.width
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: sourceImage
                        source: sourceImage
                        maskSource: imgMask
                    }

                    // Dim overlay
                    Rectangle {
                        anchors.fill: sourceImage
                        color: "black"
                        radius: imgMask.radius
                        opacity: (isHovered || isCurrent) ? 0.0 : 0.35
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }

                    // ── Confirmed badge ────────────────────────────
                    Rectangle {
                        visible: isConfirmed
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 8
                        anchors.rightMargin: 8
                        width: 22
                        height: 22
                        radius: 11
                        color: Theme.selected

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: "white"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    // ── Filename on hover ──────────────────────────
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 28
                        color: Qt.rgba(0, 0, 0, 0.6)
                        radius: Theme.radius
                        visible: isHovered || isCurrent

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            text: {
                                // Αφαίρεση extension
                                let parts = (model.fileName || "").split(".");
                                parts.pop();
                                return parts.join(".");
                            }
                            color: "white"
                            font.family: Theme.fontName
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: {
                            if (wallpaperList.keyboardNavigating)
                                return;
                            restoreTimer.stop();
                            wallpaperList.currentIndex = index;
                            root.previewPath = delegateItem.itemPath;
                            previewTimer.restart();
                        }

                        onClicked: {
                            let path = delegateItem.itemPath;
                            root.confirmedPath = path;
                            root.previewPath = "";
                            previewTimer.stop();
                            WallpaperService.setWallpaper(path, root.applyDynamicColors);
                        }
                    }
                }
            }
        }
    }

    // ── Empty state ───────────────────────────────────────────────
    Text {
        anchors.centerIn: parent
        visible: WallpaperService.model.count === 0
        text: "No wallpapers found in\n" + WallpaperService.wallpaperDir
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 13
        opacity: 0.45
        horizontalAlignment: Text.AlignHCenter
    }
}
