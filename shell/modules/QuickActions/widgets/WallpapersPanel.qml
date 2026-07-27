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

    // Was (spacing * 3) / (margins * 3) — mainColumn has 3 children,
    // so only 2 gaps between them (spacing appears N-1 times, not N),
    // and anchors.margins only adds twice to a HEIGHT total (top +
    // bottom), not three times. Was overestimating slightly, leaving
    // a bit of extra empty space at the bottom.
    implicitHeight: headerRow.implicitHeight + dividerRect.height + root.cardHeight + (mainColumn.spacing * 2) + (mainColumn.anchors.margins * 2)

    property bool applyColors: true
    property string selectedMode: Colors.mode
    property string confirmedPath: Colors.wallpaper
    property string previewPath: ""
    property bool loading: true

    Component.onCompleted: {
        wallpaperList.forceActiveFocus();
        ThemeActions.fetchWallpapers();
    }
    Component.onDestruction: {
        if (root.confirmedPath !== "")
            ThemeActions.previewWallpaper(root.confirmedPath);
    }

    Connections {
        target: ThemeActions
        function onWallpapersLoaded() {
            root.loading = false;
        }
    }

    Timer {
        id: previewTimer
        interval: 250
        onTriggered: {
            if (root.previewPath !== "")
                ThemeActions.previewWallpaper(root.previewPath);
        }
    }

    Timer {
        id: restoreTimer
        interval: 150
        onTriggered: {
            if (root.previewPath === "" && root.confirmedPath !== "")
                ThemeActions.previewWallpaper(root.confirmedPath);
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
                    text: root.loading ? "Loading..." : ThemeActions.wallpapers.length + " found"
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
                visible: root.applyColors
                opacity: root.applyColors ? 1.0 : 0.0
                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
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
                        Anim {
                            type: Anim.FastEffects
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
                        Anim {
                            type: Anim.FastEffects
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
                checked: root.applyColors
                onToggled: root.applyColors = !root.applyColors
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
            model: ThemeActions.wallpapers
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
                    ThemeActions.setWallpaper(currentItem.itemPath, root.applyColors, root.selectedMode);
                }
            }

            delegate: Item {
                id: delegateItem

                property string itemPath: modelData.path
                property bool isHovered: mouseArea.containsMouse
                property bool isCurrent: wallpaperList.currentIndex === index
                property bool isConfirmed: Colors.wallpaper === itemPath

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
                            Anim {
                                type: Anim.FastToggle
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: sourceImage
                        color: "black"
                        radius: imgMask.radius
                        opacity: (isHovered || isCurrent) ? 0.0 : 0.35
                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
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
                            ThemeActions.setWallpaper(delegateItem.itemPath, root.applyColors, root.selectedMode);
                        }
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: ThemeActions.wallpapers.length === 0
        text: root.loading ? "Loading wallpapers..." : "No wallpapers found in\n~/Pictures/Wallpapers"
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 13
        opacity: 0.45
        horizontalAlignment: Text.AlignHCenter
    }
}
