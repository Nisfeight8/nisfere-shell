import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: parent.width

    readonly property real listHeight: Screen.height * 0.25

    implicitHeight: headerRow.implicitHeight + dividerRect.height + root.listHeight + (mainColumn.spacing * 2) + (mainColumn.anchors.margins * 2)

    property bool loading: true
    property string activeMode: DynamicColors.mode

    signal requestBack

    Component.onCompleted: {
        themeList.forceActiveFocus();
        ThemeService.fetchThemes();
    }

    Connections {
        target: ThemeService
        function onThemesLoaded() {
            root.loading = false;
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
                    text: "Color Themes"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: root.loading ? "Loading..." : ThemeService.themes.length + " themes available"
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    opacity: 0.45
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "Light"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12
                opacity: root.activeMode === "light" ? 1.0 : 0.4
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                width: 44
                height: 24
                radius: 12
                color: root.activeMode === "dark" ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.9) : Theme.backgroundAlt
                border.color: root.activeMode === "dark" ? Theme.selected : Theme.borderColor
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

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.activeMode === "dark" ? parent.width - width - 3 : 3
                    color: "white"
                    opacity: root.activeMode === "dark" ? 1.0 : 0.55
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
                    onClicked: root.activeMode = root.activeMode === "dark" ? "light" : "dark"
                }
            }

            Text {
                text: "Dark"
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12
                opacity: root.activeMode === "dark" ? 1.0 : 0.4
                verticalAlignment: Text.AlignVCenter
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

        // ── Theme list ─────────────────────────────────────────────
        ListView {
            id: themeList

            Layout.fillWidth: true
            // ✅ Explicit literal — ίδιο fix με WallpaperManager's ListView
            Layout.preferredHeight: root.listHeight

            orientation: ListView.Vertical
            spacing: 8
            clip: true
            model: ThemeService.themes
            boundsBehavior: Flickable.StopAtBounds
            focus: true
            activeFocusOnTab: true

            property bool keyboardNavigating: false

            Timer {
                id: keyboardLockTimer
                interval: 600
                onTriggered: themeList.keyboardNavigating = false
            }

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
                if (currentItem?.itemName)
                    ThemeService.setColors(currentItem.itemName, root.activeMode);
            }

            delegate: Rectangle {
                id: delegateItem

                property string itemName: modelData.name
                property bool isHovered: mouseArea.containsMouse
                property bool isCurrent: themeList.currentIndex === index
                property bool isConfirmed: DynamicColors.sourceType === "static" && DynamicColors.sourceName === modelData.name

                width: ListView.view.width
                height: 55
                radius: Theme.radius

                color: isConfirmed ? Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.15) : (isHovered || isCurrent ? Theme.backgroundAlt : "transparent")

                border.width: 1
                border.color: isConfirmed ? Theme.selected : (isHovered || isCurrent ? Theme.borderColor : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 15

                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: delegateItem.isConfirmed ? Theme.selected : Theme.foreground
                        opacity: delegateItem.isConfirmed ? 1.0 : (delegateItem.isHovered || delegateItem.isCurrent ? 0.6 : 0.3)
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0   // ✅ defensive — elide-safe (ίδιο pattern με MiniMedia)
                        text: modelData.name
                        color: delegateItem.isConfirmed ? Theme.selected : Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 15
                        font.bold: delegateItem.isConfirmed || delegateItem.isHovered || delegateItem.isCurrent
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: delegateItem.isConfirmed
                        width: modeLabel.implicitWidth + 12
                        height: 20
                        radius: 10
                        color: Qt.rgba(Theme.selected.r, Theme.selected.g, Theme.selected.b, 0.2)

                        Text {
                            id: modeLabel
                            anchors.centerIn: parent
                            text: DynamicColors.mode
                            color: Theme.selected
                            font.family: Theme.fontName
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        visible: delegateItem.isConfirmed
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
                    onClicked: themeList._confirmCurrent()
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: ThemeService.themes.length === 0
        text: root.loading ? "Loading themes..." : "No themes found in\n~/.config/nisfere/themes/"
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 13
        opacity: 0.45
        horizontalAlignment: Text.AlignHCenter
    }
}
