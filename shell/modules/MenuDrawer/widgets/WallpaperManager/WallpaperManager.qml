import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.core
import qs.services

Item {
    id: root
    anchors.fill: parent

    property bool applyDynamicColors: true
    property string selectedMode:     DynamicColors.mode
    property string confirmedPath:    DynamicColors.wallpaper
    property string previewPath:      ""
    property bool loading:            true

    Component.onCompleted: {
        wallpaperList.forceActiveFocus();
        ThemeService.fetchWallpapers();
    }

    Connections {
        target: ThemeService
        function onWallpapersLoaded() { root.loading = false; }
    }

    // ── Debounce: preview μόνο αν ο χρήστης μείνει 250ms ─────────
    Timer {
        id: previewTimer
        interval: 250
        onTriggered: {
            if (root.previewPath !== "")
                ThemeService.previewWallpaper(root.previewPath);
        }
    }

    // ── Restore: μικρό delay πριν επαναφορά ──────────────────────
    Timer {
        id: restoreTimer
        interval: 150
        onTriggered: {
            if (root.previewPath === "" && root.confirmedPath !== "")
                ThemeService.previewWallpaper(root.confirmedPath);
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
                    text: root.loading
                        ? "Loading..."
                        : ThemeService.wallpapers.length + " found"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 10
                    opacity: 0.45
                }
            }

            Item { Layout.fillWidth: true }

            // ── Light / Dark toggle — only when dynamic colors is on ──
            RowLayout {
                spacing: 6
                visible: root.applyDynamicColors
                opacity: root.applyDynamicColors ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Text {
                    text: "Light"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    opacity: root.selectedMode === "light" ? 0.9 : 0.35
                    verticalAlignment: Text.AlignVCenter
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }

                Rectangle {
                    width: 40
                    height: 22
                    radius: 11
                    color: root.selectedMode === "dark"
                        ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.85)
                        : Theme.backgroundAlt
                    border.color: root.selectedMode === "dark" ? Theme.selected : Theme.borderColor
                    border.width: 1
                    Behavior on color       { ColorAnimation { duration: 160 } }
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    Rectangle {
                        width: 16; height: 16; radius: 8
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.selectedMode === "dark" ? parent.width - width - 3 : 3
                        color: "white"
                        opacity: root.selectedMode === "dark" ? 1.0 : 0.55
                        Behavior on x       { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedMode = root.selectedMode === "dark" ? "light" : "dark"
                    }
                }

                Text {
                    text: "Dark"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    opacity: root.selectedMode === "dark" ? 0.9 : 0.35
                    verticalAlignment: Text.AlignVCenter
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }

                // Vertical separator
                Rectangle {
                    width: 1; height: 18
                    color: Theme.borderColor
                    opacity: 0.5
                }
            }

            // ── Dynamic colors toggle ─────────────────────────────
            Text {
                text: "Dynamic colors"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12
                opacity: 0.7
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: 44
                height: 24
                radius: 12
                color: root.applyDynamicColors
                    ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.9)
                    : Theme.backgroundAlt
                border.color: root.applyDynamicColors ? Theme.selected : Theme.borderColor
                border.width: 1
                Behavior on color       { ColorAnimation { duration: 160 } }
                Behavior on border.color { ColorAnimation { duration: 160 } }

                Rectangle {
                    width: 18; height: 18; radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.applyDynamicColors ? parent.width - width - 3 : 3
                    color: "white"
                    opacity: root.applyDynamicColors ? 1.0 : 0.55
                    Behavior on x       { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
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

        // ── Wallpaper List ────────────────────────────────────────
        ListView {
            id: wallpaperList
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            spacing: 10
            clip: true
            model: ThemeService.wallpapers
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

            Keys.onLeftPressed:  { keyboardNavigating = true; keyboardLockTimer.restart(); decrementCurrentIndex(); }
            Keys.onRightPressed: { keyboardNavigating = true; keyboardLockTimer.restart(); incrementCurrentIndex(); }
            Keys.onReturnPressed: _confirmCurrent()
            Keys.onEnterPressed:  _confirmCurrent()

            onCurrentItemChanged: {
                if (currentItem?.itemPath) {
                    root.previewPath = currentItem.itemPath;
                    previewTimer.restart();
                    restoreTimer.stop();
                }
            }

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
                if (currentItem?.itemPath) {
                    root.confirmedPath = currentItem.itemPath;
                    root.previewPath = "";
                    previewTimer.stop();
                    ThemeService.setWallpaper(
                        currentItem.itemPath,
                        root.applyDynamicColors,
                        root.selectedMode
                    );
                }
            }

            delegate: Item {
                id: delegateItem

                property string itemPath:  modelData.path
                property bool isHovered:   mouseArea.containsMouse
                property bool isCurrent:   wallpaperList.currentIndex === index
                property bool isConfirmed: DynamicColors.wallpaper === itemPath

                width: 300
                height: wallpaperList.height

                Rectangle {
                    id: card
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Theme.radius
                    color: "transparent"

                    border.width: isConfirmed || isHovered || isCurrent ? 2 : 1
                    border.color: isConfirmed
                        ? Theme.selected
                        : (isHovered || isCurrent
                            ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.5)
                            : Theme.borderColor)

                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    Behavior on border.width  { NumberAnimation { duration: 150 } }

                    Image {
                        id: sourceImage
                        anchors.fill: parent
                        anchors.margins: card.border.width
                        source: "file://" + modelData.path
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                        scale: (isHovered || isCurrent) ? 1.04 : 1.0
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
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

                    Rectangle {
                        anchors.fill: sourceImage
                        color: "black"
                        radius: imgMask.radius
                        opacity: (isHovered || isCurrent) ? 0.0 : 0.35
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    // ── Confirmed badge ────────────────────────────
                    Rectangle {
                        visible: isConfirmed
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 8
                        anchors.rightMargin: 8
                        width: 22; height: 22; radius: 11
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
                            text: modelData.name
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
                            if (wallpaperList.keyboardNavigating) return;
                            restoreTimer.stop();
                            wallpaperList.currentIndex = index;
                            root.previewPath = delegateItem.itemPath;
                            previewTimer.restart();
                        }

                        onClicked: {
                            root.confirmedPath = delegateItem.itemPath;
                            root.previewPath = "";
                            previewTimer.stop();
                            ThemeService.setWallpaper(
                                delegateItem.itemPath,
                                root.applyDynamicColors,
                                root.selectedMode
                            );
                        }
                    }
                }
            }
        }
    }

    // ── Empty / loading state ─────────────────────────────────────
    Text {
        anchors.centerIn: parent
        visible: ThemeService.wallpapers.length === 0
        text: root.loading
            ? "Loading wallpapers..."
            : "No wallpapers found in\n~/Pictures/Wallpapers"
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 13
        opacity: 0.45
        horizontalAlignment: Text.AlignHCenter
    }
}
