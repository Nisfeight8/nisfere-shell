import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets/WallpaperManager"
import "widgets/DockerManager"
import "widgets/ThemeManager"

BaseDrawer {
    id: menuDrawer

    edge: Qt.BottomEdge
    focusable: opened
    opened: ShellState.menuDrawerOpened

    minPanelWidth: Screen.width * 0.32
    panelHeight: Screen.height / 2.8

    property int currentAppIndex: -1
    property string currentAppTitle: "Nisfere Tools"

    property var appMenu: [
        {
            title: "Wallpapers",
            icon: "image",
            index: 0
        },
        {
            title: "Colors",
            icon: "palette",
            index: 1
        },
        {
            title: "Docker",
            icon: "box",
            index: 2
        }
    ]

    onCloseRequest: ShellState.menuDrawerOpened = false
    onOpenRequest: ShellState.menuDrawerOpened = true
    onToggleRequest: ShellState.menuDrawerOpened = !ShellState.menuDrawerOpened

    contentComponent: Component {

        Item {
            id: rootContent

            property real _lastWidth: 200
            property real _lastHeight: 1500

            implicitWidth: _lastWidth
            implicitHeight: _lastHeight

            function _syncSize() {
                const item = pageLoader.item;
                if (!item)
                    return;
                if (item.implicitWidth > 0)
                    _lastWidth = item.implicitWidth;
                if (item.implicitHeight > 0)
                    _lastHeight = item.implicitHeight;
            }

            Component.onCompleted: {
                forceActiveFocus();
            }

            Connections {
                target: pageLoader.item
                function onImplicitWidthChanged() {
                    rootContent._syncSize();
                }
                function onImplicitHeightChanged() {
                    rootContent._syncSize();
                }
            }
            Connections {
                target: menuDrawer
                function onCurrentAppIndexChanged() {
                    if (menuDrawer.currentAppIndex !== -1) {
                        rootContent.forceActiveFocus();
                    }
                }
            }

            function goBack() {
                currentAppIndex = -1;
                currentAppTitle = "Nisfere Tools";
            }

            Keys.onEscapePressed: {
                if (currentAppIndex !== -1) {
                    goBack();
                } else {
                    ShellState.menuDrawerOpened = false;
                }
            }

            Keys.onLeftPressed: {
                if (currentAppIndex !== -1) {
                    goBack();
                }
            }

            // ── Page Components ──────────────────────────────────────
            Component {
                id: menuPageComp

                Item {
                    id: appMenuList

                    implicitWidth: appMenuColumn.implicitWidth
                    implicitHeight: appMenuColumn.implicitHeight

                    property int currentIndex: 0
                    property bool keyboardNavigating: false

                    focus: true
                    Component.onCompleted: forceActiveFocus()

                    Timer {
                        id: keyboardLockTimer
                        interval: 600
                        onTriggered: appMenuList.keyboardNavigating = false
                    }

                    function _confirmCurrent() {
                        var item = menuDrawer.appMenu[currentIndex];
                        if (item) {
                            menuDrawer.currentAppTitle = item.title;
                            menuDrawer.currentAppIndex = item.index;
                        }
                    }

                    Keys.onUpPressed: {
                        keyboardNavigating = true;
                        keyboardLockTimer.restart();
                        currentIndex = Math.max(0, currentIndex - 1);
                    }
                    Keys.onDownPressed: {
                        keyboardNavigating = true;
                        keyboardLockTimer.restart();
                        currentIndex = Math.min(menuDrawer.appMenu.length - 1, currentIndex + 1);
                    }
                    Keys.onReturnPressed: _confirmCurrent()
                    Keys.onEnterPressed: _confirmCurrent()
                    Keys.onRightPressed: _confirmCurrent()

                    ColumnLayout {
                        id: appMenuColumn
                        anchors.fill: parent
                        spacing: 10

                        Repeater {
                            model: menuDrawer.appMenu

                            delegate: Rectangle {
                                id: delegateItem

                                property bool isHovered: itemMouse.containsMouse
                                property bool isCurrent: appMenuList.currentIndex === index

                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                implicitWidth: itemRow.implicitWidth + 30
                                radius: Theme.radius
                                color: (isHovered || isCurrent) ? Theme.backgroundAlt : "transparent"

                                RowLayout {
                                    id: itemRow
                                    anchors.fill: parent
                                    anchors.margins: 15
                                    spacing: 20

                                    LucideIcon {
                                        icon: modelData.icon
                                        size: 24
                                        color: Theme.selected
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        font.family: Theme.fontName
                                        font.pixelSize: 16
                                        color: Theme.foreground
                                        font.bold: delegateItem.isHovered || delegateItem.isCurrent
                                    }
                                    LucideIcon {
                                        icon: "chevron-right"
                                        size: 18
                                        color: Theme.foreground
                                        opacity: 0.5
                                    }
                                }

                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onEntered: {
                                        if (appMenuList.keyboardNavigating)
                                            return;
                                        appMenuList.currentIndex = index;
                                    }
                                    onClicked: {
                                        appMenuList.currentIndex = index;
                                        appMenuList._confirmCurrent();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: wallpaperPageComp
                WallpaperManager {}
            }
            Component {
                id: themePageComp
                ThemeManager {}
            }
            Component {
                id: dockerPageComp
                DockerManager {}
            }

            ColumnLayout {
                id: mainColumn
                anchors.fill: parent
                spacing: 15

                // ── Header ────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    spacing: 15

                    Rectangle {
                        width: 30
                        height: 30
                        radius: Theme.radius
                        color: backMouse.containsMouse ? Theme.backgroundAlt : "transparent"
                        visible: currentAppIndex !== -1

                        LucideIcon {
                            anchors.centerIn: parent
                            icon: "chevron-left"
                            size: 20
                            color: Theme.foreground
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootContent.goBack()
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: currentAppTitle
                        font.family: Theme.fontName
                        font.pixelSize: 18
                        font.bold: true
                        color: Theme.foreground
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // ── AnimLoader — μία σελίδα τη φορά, με fade transition ──
                AnimLoader {
                    id: pageLoader
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    onItemChanged: rootContent._syncSize()

                    sourceComp: {
                        switch (currentAppIndex) {
                        case -1:
                            return menuPageComp;
                        case 0:
                            return wallpaperPageComp;
                        case 1:
                            return themePageComp;
                        case 2:
                            return dockerPageComp;
                        default:
                            return menuPageComp;
                        }
                    }
                }

                // ✅ Δυναμικό target — ενεργό μόνο όταν είναι φορτωμένο το WallpaperManager
                Connections {
                    target: menuDrawer.currentAppIndex === 0 ? pageLoader.item : null
                    function onRequestBack() {
                        rootContent.goBack();
                    }
                }
            }
        }
    }
}
