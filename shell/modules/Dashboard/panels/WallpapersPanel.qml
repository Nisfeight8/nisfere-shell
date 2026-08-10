import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.core
import qs.services

Item {
    id: root

    property string searchText: ""

    // ── Content-driven sizing ──────────────────────────────────
    // Fixed pixel sizes now (not Screen.width/height-relative like the
    // original bottom-drawer version) — this lives inside a bounded
    // Dashboard drawer (maxPanelHeight: 500), not a full-width bottom
    // sheet, so sizing needs to be predictable regardless of monitor
    // resolution rather than scaling with the screen.
    readonly property real cardHeight: 140
    readonly property real cardWidth: cardHeight * 16 / 9
    readonly property int visibleCards: 4
    readonly property real listSpacing: 10
    readonly property real outerMargins: 12

    implicitWidth: (root.cardWidth * root.visibleCards) + (root.listSpacing * (root.visibleCards - 1)) + (root.outerMargins * 2)
    implicitHeight: headerRow.implicitHeight + dividerRect.height + root.cardHeight + (mainColumn.spacing * 2) + (mainColumn.anchors.margins * 2)

    property bool applyColors: true
    property string selectedMode: Colors.mode
    property string confirmedPath: Colors.wallpaper
    property string previewPath: ""
    property bool loading: true

    readonly property var filteredWallpapers: root.searchText === "" ? ThemeActions.wallpapers : ThemeActions.wallpapers.filter(w => w.name.toLowerCase().includes(root.searchText.toLowerCase()))

    // ── navigate()/activateSelected() contract — same shape as every
    // other inline search provider (AppLauncherPanel, GenericResultsList).
    // Mapped to Up/Down (NOT Left/Right) deliberately: Left/Right stay
    // free for normal text-cursor movement inside the search bar, since
    // this panel renders WHILE the user may still be typing. Own
    // forceActiveFocus() + Keys.onLeftPressed/onRightPressed from the
    // original standalone version are removed for the same reason —
    // this component no longer owns keyboard focus itself.
    function navigate(delta) {
        wallpaperList.keyboardNavigating = true;
        keyboardLockTimer.restart();
        if (delta < 0)
            wallpaperList.decrementCurrentIndex();
        else
            wallpaperList.incrementCurrentIndex();
    }
    function activateSelected() {
        wallpaperList._confirmCurrent();
    }

    onSearchTextChanged: {
        if (wallpaperList.currentIndex >= root.filteredWallpapers.length)
            wallpaperList.currentIndex = 0;
    }

    Component.onCompleted: {
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
        anchors.margins: root.outerMargins
        spacing: root.outerMargins

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
                    text: root.loading ? "Loading..." : root.filteredWallpapers.length + " found"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 10
                    opacity: 0.45
                }
            }

            Item {
                Layout.fillWidth: true
            }

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
            spacing: root.listSpacing
            clip: true
            model: root.filteredWallpapers
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 200

            property bool keyboardNavigating: false

            Timer {
                id: keyboardLockTimer
                interval: 600
                onTriggered: wallpaperList.keyboardNavigating = false
            }

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
                        asynchronous: true
                        cache: true
                        visible: false
                        sourceSize.width: root.cardWidth * 2
                        sourceSize.height: root.cardHeight * 2
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
        visible: root.filteredWallpapers.length === 0
        text: root.loading ? "Loading wallpapers..." : (root.searchText !== "" ? "No matching wallpapers" : "No wallpapers found in\n~/Pictures/Wallpapers")
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 13
        opacity: 0.45
        horizontalAlignment: Text.AlignHCenter
    }
}
