import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

import qs.core

BarWidget {
    id: root

    readonly property string screenName: QsWindow.window?.screen?.name ?? ""

    readonly property var activeWin: {
        return ToplevelManager.toplevels.values.find(t => t.activated && t.screens.some(s => s.name === root.screenName)) ?? null;
    }

    readonly property bool hasWindow: activeWin !== null
    readonly property string windowClass: hasWindow ? activeWin.appId : ""
    readonly property string windowTitle: hasWindow ? activeWin.title : "Desktop"
    readonly property string iconName: hasWindow && windowClass !== "" ? Icons.getAppIcon(windowClass) : Icons.getAppIcon("desktop")
    useGradient: true

    readonly property bool isHovered: winHover.hovered
    // Was `showPopup: root.isHovered` directly — the moment the mouse
    // crosses from the widget toward the popup (a separate window
    // below it), it briefly leaves BOTH regions, so isHovered flips to
    // false instantly and closes the popup while the user is still
    // trying to reach it. Same debounce pattern BaseDrawer already
    // uses (autoCloseTimer): only actually close after a short grace
    // period with NEITHER the widget NOR the popup content hovered.
    property bool popupOpen: false
    property bool popupContentHovered: false
    readonly property bool anyHovered: winHover.hovered || root.popupContentHovered

    // Was `captureSource: winPopup.showPopup ? root.activeWin : null`
    // — nulled out the INSTANT closing starts, well before the
    // container's own 550ms close-fade finishes (same grace window as
    // DelayedUnloadLoader). The screenshot preview would freeze/blank
    // right at the start of the fade instead of staying valid for the
    // whole visible-including-fading-out lifetime. Mirrors the same
    // grace window here so it only goes null once the fade is
    // actually done (by which point it's invisible anyway).
    property bool captureActive: false

    onPopupOpenChanged: {
        if (popupOpen) {
            captureStopTimer.stop();
            captureActive = true;
        } else {
            captureStopTimer.restart();
        }
    }

    Timer {
        id: captureStopTimer
        interval: AnimTokens.durationDefaultSpatial + 50
        onTriggered: root.captureActive = false
    }

    onAnyHoveredChanged: {
        if (anyHovered) {
            closeTimer.stop();
            popupOpen = true;
        }
    }

    Timer {
        id: closeTimer
        interval: 150
        running: !root.anyHovered && root.popupOpen
        onTriggered: root.popupOpen = false
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.selected
        font.family: Theme.fontName
        font.pixelSize: 14
        text: root.iconName
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.foreground
        font.family: Theme.fontName
        font.pixelSize: 13
        text: root.windowTitle.length > 40 ? root.windowTitle.substring(0, 40) + "..." : root.windowTitle
    }

    HoverHandler {
        id: winHover
        parent: root
        cursorShape: Qt.PointingHandCursor
    }

    BarPopup {
        id: winPopup

        showPopup: root.popupOpen
        targetItem: root

        ColumnLayout {
            spacing: 10

            // Tracks hover over the POPUP ITSELF — writes to root's
            // own popupContentHovered property (ids declared inside
            // this Component aren't visible outside it, but `root` IS
            // visible from in here, so writing outward is the correct
            // direction). Combined with winHover via `anyHovered`, so
            // moving the mouse onto the popup keeps it open instead of
            // racing the widget's own hover state back to false.
            HoverHandler {
                onHoveredChanged: root.popupContentHovered = hovered
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.foreground
                font.bold: true
                font.family: Theme.fontName
                font.pixelSize: 17
                text: root.hasWindow ? root.windowClass : "System"
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 320
                color: Theme.foreground
                font.family: Theme.fontName
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.8
                text: root.hasWindow ? root.windowTitle : "You are viewing the Desktop."
                wrapMode: Text.Wrap
            }
            ScreencopyView {
                id: captureView

                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                captureSource: root.captureActive ? root.activeWin : null
                constraintSize: Qt.size(320, 200)
                live: true
                visible: false
            }
            OpacityMask {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: captureView.height
                Layout.preferredWidth: captureView.width
                source: captureView
                visible: root.hasWindow && captureView.hasContent

                maskSource: Rectangle {
                    height: captureView.height
                    radius: Theme.radius
                    width: captureView.width
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.selected
                font.family: Theme.fontName
                font.pixelSize: 32
                text: root.iconName
                visible: !root.hasWindow
            }
        }
    }
}
