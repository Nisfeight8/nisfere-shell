import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import qs.core
import qs.services

Item {
    id: root

    anchors.fill: parent
    implicitWidth: parent.width
    implicitHeight: parent.height

    property real artSize: ringOuter * 0.6
    property real ringOuter: 290
    property real rowSpacing: 40
    property real safeHeight: root.height > 0 ? root.height : 300
    property real safeWidth: root.width > 0 ? root.width : 400
    property real strokeSize: Math.max(6, ringOuter * 0.05)
    property real trackRadius: (ringOuter - strokeSize) / 2
    property bool dropdownOpen: false   // fully self-managed player-switcher dropdown state

    function formatTime(position) {
        let seconds = (MediaService.length > 10000) ? Math.floor(position / 1000000) : Math.floor(position);
        let m = Math.floor(seconds / 60);
        let s = seconds % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    RowLayout {
        id: content
        anchors.fill: parent
        spacing: root.rowSpacing

        Item {
            id: artWrapper
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: root.ringOuter
            Layout.preferredWidth: root.ringOuter

            Rectangle {
                id: glow
                anchors.centerIn: parent
                color: Theme.selected
                height: root.artSize + 20
                opacity: 0.15 + (AudioVisualizer.bass / 2000)
                radius: width / 2
                scale: Math.max(1.0, 1.0 + (AudioVisualizer.bass / 3000))
                width: height

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }
                Behavior on scale {
                    Anim {
                        type: Anim.FastEffects
                    }
                }
            }

            Item {
                anchors.centerIn: parent
                height: root.artSize
                width: root.artSize

                Image {
                    id: coverImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: MediaService.albumArt
                    visible: false
                }
                Rectangle {
                    id: circleMask
                    anchors.fill: parent
                    color: "black"
                    radius: width / 2
                    visible: false
                }
                OpacityMask {
                    anchors.fill: parent
                    maskSource: circleMask
                    source: coverImage
                    visible: MediaService.albumArt !== ""
                }
                Rectangle {
                    anchors.fill: parent
                    border.color: Theme.borderColor
                    border.width: 3
                    color: "transparent"
                    radius: width / 2
                    visible: MediaService.albumArt !== ""
                }
                Rectangle {
                    anchors.fill: parent
                    border.color: Theme.borderColor
                    border.width: 3
                    color: Theme.background
                    radius: width / 2
                    visible: MediaService.albumArt === ""

                    LucideIcon {
                        anchors.centerIn: parent
                        color: Theme.foreground
                        size: Math.max(24, root.artSize * 0.35)
                        opacity: 0.3
                        icon: "music"
                    }
                }
            }
        }

        ColumnLayout {
            id: rightCol
            Layout.preferredWidth: root.ringOuter * 1.6
            spacing: Math.max(6, root.ringOuter * 0.06)

            // ── Player switcher ────────────────────────────────────
            Item {
                Layout.alignment: Qt.AlignCenter
                height: 30
                width: contentRow.implicitWidth

                RowLayout {
                    id: contentRow
                    anchors.centerIn: parent
                    opacity: playerMouse.containsMouse || root.dropdownOpen ? 1.0 : 0.7
                    spacing: 8
                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }

                    Text {
                        color: Theme.selected
                        font.family: Theme.fontName
                        font.pixelSize: 14
                        text: Icons.getPlayerIcon(MediaService.active)
                    }
                    Text {
                        color: Theme.foreground
                        elide: Text.ElideRight
                        font.bold: true
                        font.family: Theme.fontName
                        font.letterSpacing: 2.
                        font.pixelSize: 11
                        text: MediaService.hasPlayer ? MediaService.active.identity.toUpperCase() : "NO ACTIVE PLAYER"
                    }
                    LucideIcon {
                        color: Theme.selected
                        size: 22
                        opacity: 0.7
                        icon: root.dropdownOpen ? "chevron-up" : "chevron-down"
                        visible: MediaService.list.length > 1
                    }
                }

                MouseArea {
                    id: playerMouse
                    anchors.fill: parent
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: MediaService.list.length > 1
                    hoverEnabled: true
                    onClicked: {
                        // Drive open/closed entirely via our OWN boolean —
                        // not by reading playerDropdown.opened — and don't
                        // rely on the Popup's built-in closePolicy at all
                        // (Popup inside a Quickshell PanelWindow may not
                        // have a proper Overlay backing it, so its
                        // automatic outside-press-close behavior isn't
                        // reliable here). This sidesteps that entirely.
                        root.dropdownOpen = !root.dropdownOpen;
                    }
                }

                Popup {
                    id: playerDropdown
                    padding: 5
                    width: 160
                    x: (parent.width - width)
                    y: parent.height + 5

                    // Fully controlled by our own property — no
                    // closePolicy-driven auto-close at all.
                    closePolicy: Popup.NoAutoClose
                    visible: root.dropdownOpen

                    background: Rectangle {
                        border.color: Theme.borderColor
                        border.width: 1
                        color: Theme.backgroundAlt
                        radius: 8
                    }
                    contentItem: ColumnLayout {
                        spacing: 4

                        Repeater {
                            model: MediaService.list

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                color: dropMouse.containsMouse ? Theme.selected : "transparent"
                                height: 32
                                radius: 6
                                Behavior on color {
                                    AnimColor {
                                        type: Anim.FastEffects
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    color: dropMouse.containsMouse ? Theme.background : Theme.foreground
                                    font.bold: true
                                    font.family: Theme.fontName
                                    font.letterSpacing: 1.5
                                    font.pixelSize: 11
                                    text: MediaService.getIdentity(modelData).toUpperCase()
                                    Behavior on color {
                                        AnimColor {
                                            type: Anim.FastEffects
                                        }
                                    }
                                }
                                MouseArea {
                                    id: dropMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        MediaService.selectPlayer(index);
                                        root.dropdownOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Title + artist ──────────────────────────────────────
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: Theme.foreground
                    elide: Text.ElideRight
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 34
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 2
                    text: MediaService.title
                    wrapMode: Text.Wrap
                }
                Text {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: Theme.foreground
                    elide: Text.ElideRight
                    font.family: Theme.fontName
                    font.pixelSize: 24
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.7
                    text: MediaService.artist !== "" ? MediaService.artist : "Unknown Artist"
                }
            }

            // ── Time ─────────────────────────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                spacing: 8

                Text {
                    color: Theme.selected
                    font.bold: true
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    text: formatTime(MediaService.position)
                }
                Text {
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    opacity: 0.3
                    text: "/"
                }
                Text {
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    opacity: 0.7
                    text: root.formatTime(MediaService.length)
                }
            }

            MediaSlider {
                id: bigMediaSlider
                Layout.fillWidth: true
            }

            // ── Transport controls ──────────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: Math.max(4, root.ringOuter * 0.06)
                spacing: Math.max(14, root.ringOuter * 0.16)

                IconButton {
                    icon: "skip-back"
                    flat: true
                    size: Math.max(20, root.ringOuter * 0.10)
                    iconSize: Math.max(20, root.ringOuter * 0.10)
                    fixedIconColor: Theme.foreground
                    idleOpacity: 0.6
                    onTapped: MediaService.previous()
                }

                // Big play/pause — solid circle, uses IconButton's exposed
                // `pressed` state for the same press-scale effect as
                // MiniMedia's play button.
                IconButton {
                    id: bigPlayBtn
                    readonly property real btnSize: Math.min(65, Math.max(45, root.ringOuter * 0.35))

                    icon: Icons.getPlayPauseIcon(MediaService.isPlaying)
                    size: btnSize
                    iconSize: btnSize * 0.45
                    radius: btnSize / 2
                    normalColor: Theme.selected
                    activeSolid: true
                    isActive: true
                    contrastColor: Theme.background
                    scale: pressed ? 0.9 : 1.0
                    Behavior on scale {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }
                    onTapped: MediaService.togglePlayPause()
                }

                IconButton {
                    icon: "skip-forward"
                    flat: true
                    size: Math.max(20, root.ringOuter * 0.10)
                    iconSize: Math.max(20, root.ringOuter * 0.10)
                    fixedIconColor: Theme.foreground
                    idleOpacity: 0.6
                    onTapped: MediaService.next()
                }
            }
        }
    }
}
