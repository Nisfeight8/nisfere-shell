import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: Screen.width * 0.6

    readonly property real cardHeight: Screen.height * 0.15
    readonly property real cardWidth: cardHeight * 16 / 9   // 16:9 ratio

    implicitHeight: headerRow.implicitHeight + dividerRect.height + root.cardHeight + (mainColumn.spacing * 3) + (mainColumn.anchors.margins * 3)

    property bool applyDynamicColors: true
    property string selectedMode: DynamicColors.mode
    property string confirmedPath: DynamicColors.wallpaper
    property string previewPath: ""
    property bool loading: true

    Component.onCompleted: {
        wallpaperList.forceActiveFocus();
        ThemeService.fetchWallpapers();
    }
    Component.onDestruction: {
        if (root.confirmedPath !== "")
            ThemeService.previewWallpaper(root.confirmedPath);
    }

    Connections {
        target: ThemeService
        function onWallpapersLoaded() {
            root.loading = false;
        }
    }

    Timer {
        id: previewTimer
        interval: 250
        onTriggered: {
            if (root.previewPath !== "")
                ThemeService.previewWallpaper(root.previewPath);
        }
    }

    Timer {
        id: restoreTimer
        interval: 150
        onTriggered: {
            if (root.previewPath === "" && root.confirmedPath !== "")
                ThemeService.previewWallpaper(root.confirmedPath);
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // ── Header ────────────────────────────────────────────────
        RowLayout {
            id: headerRow
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
                    text: root.loading ? "Loading..." : ThemeService.wallpapers.length + " found"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 10
                    opacity: 0.45
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // ── Light / Dark mode toggle ───────────────────────────
            RowLayout {
                spacing: 6
                visible: root.applyDynamicColors
                opacity: root.applyDynamicColors ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }

                Text {
                    text: "Light"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    opacity: root.selectedMode === "light" ? 0.9 : 0.35
                    verticalAlignment: Text.AlignVCenter
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
                        }
                    }
                }

                ToggleSwitch {
                    checked: root.selectedMode === "dark"
                    onToggled: root.selectedMode = root.selectedMode === "dark" ? "light" : "dark"
                }

                Text {
                    text: "Dark"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    opacity: root.selectedMode === "dark" ? 0.9 : 0.35
                    verticalAlignment: Text.AlignVCenter
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: 18
                    color: Theme.borderColor
                    opacity: 0.5
                }
            }

            // ── Dynamic colors toggle ──────────────────────────────
            Text {
                text: "Dynamic colors"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12
                opacity: 0.7
                verticalAlignment: Text.AlignVCenter
            }

            ToggleSwitch {
                checked: root.applyDynamicColors
                onToggled: root.applyDynamicColors = !root.applyDynamicColors
            }
        }

        // Divider
        Rectangle {
            id: dividerRect
            Layout.fillWidth: true
            height: 1
            color: Theme.borderColor
            opacity: 0.4
        }

        // ── Wallpaper List ────────────────────────────────────────
        ListView {
            id: wallpaperList

            Layout.fillWidth: true
            Layout.preferredHeight: root.cardHeight
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
                    ThemeService.setWallpaper(currentItem.itemPath, root.applyDynamicColors, root.selectedMode);
                }
            }

            delegate: Item {
                id: delegateItem

                property string itemPath: modelData.path
                property bool isHovered: mouseArea.containsMouse
                property bool isCurrent: wallpaperList.currentIndex === index
                property bool isConfirmed: DynamicColors.wallpaper === itemPath

                width: root.cardWidth
                height: wallpaperList.height
                
                Rectangle {
                    id: card
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: Theme.radius
                    color: "transparent"
                    clip: false

                    // Border now ONLY reflects the persistently confirmed
                    // wallpaper — hover/keyboard-current feedback is
                    // entirely handled by the image scaling up below
                    // instead of an additional colored ring, which felt
                    // redundant with the scale effect.
                    border.width: isConfirmed ? 2 : 1
                    border.color: isConfirmed ? Theme.selected : Theme.borderColor
                    Behavior on border.color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }

                    Image {
                        id: sourceImage
                        anchors.fill: parent
                        anchors.margins: card.border.width
                        source: "file://" + modelData.path
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        asynchronous: true
                        visible: false
                        // NOTE: scale lives on OpacityMask below, not here.
                        // This Image is only visible:false — used purely as
                        // a texture source for OpacityMask's shader. Scaling
                        // a hidden item that feeds a ShaderEffectSource
                        // doesn't reliably grow the rendered output (the
                        // texture capture uses the item's static bounds),
                        // so the zoom has to be applied to the actually
                        // visible item instead.
                    }

                    Rectangle {
                        id: imgMask
                        anchors.fill: sourceImage
                        radius: Theme.radius - card.border.width
                        visible: false
                    }

                    OpacityMask {
                        id: maskedImage
                        anchors.fill: sourceImage
                        source: sourceImage
                        maskSource: imgMask
                        // Bigger zoom on hover/current now that the border
                        // ring is gone — this alone carries the "focused"
                        // feedback.
                        scale: (isHovered || isCurrent) ? 1.10 : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

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
                            if (wallpaperList.keyboardNavigating)
                                return;
                            restoreTimer.stop();
                            wallpaperList.currentIndex = index;
                            root.previewPath = delegateItem.itemPath;
                            previewTimer.restart();
                        }

                        onClicked: {
                            root.confirmedPath = delegateItem.itemPath;
                            root.previewPath = "";
                            previewTimer.stop();
                            ThemeService.setWallpaper(delegateItem.itemPath, root.applyDynamicColors, root.selectedMode);
                        }
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: ThemeService.wallpapers.length === 0
        text: root.loading ? "Loading wallpapers..." : "No wallpapers found in\n~/Pictures/Wallpapers"
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 13
        opacity: 0.45
        horizontalAlignment: Text.AlignHCenter
    }
}
