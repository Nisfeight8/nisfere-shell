import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: content.width
    implicitHeight: content.height

    property real artSize: ringOuter * 0.6
    property real ringOuter: 250
    property real rowSpacing: 40
    property real safeHeight: root.height > 0 ? root.height : 300
    property real safeWidth: root.width > 0 ? root.width : 400
    property real strokeSize: Math.max(6, ringOuter * 0.05)
    property real trackRadius: (ringOuter - strokeSize) / 2

    function formatTime(position) {
        let seconds = (MediaService.length > 10000) ? Math.floor(position / 1000000) : Math.floor(position);
        let m = Math.floor(seconds / 60);
        let s = seconds % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    RowLayout {
        id: content

        // anchors.centerIn: parent
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
                    NumberAnimation {
                        duration: 120
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 80
                        easing.type: Easing.OutQuint
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

            Item {
                Layout.alignment: Qt.AlignCenter
                height: 30
                width: contentRow.implicitWidth

                RowLayout {
                    id: contentRow

                    anchors.centerIn: parent
                    opacity: playerMouse.containsMouse || playerDropdown.opened ? 1.0 : 0.7
                    spacing: 8

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
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
                        icon: playerDropdown.opened ? "chevron-up" : "chevron-down"
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
                        if (playerDropdown.opened) {
                            playerDropdown.close();
                        } else {
                            playerDropdown.open();
                        }
                    }
                }
                Popup {
                    id: playerDropdown

                    padding: 5
                    width: 160
                    x: (parent.width - width)
                    y: parent.height + 5

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

                                Text {
                                    anchors.centerIn: parent
                                    color: dropMouse.containsMouse ? Theme.background : Theme.foreground
                                    font.bold: true
                                    font.family: Theme.fontName
                                    font.letterSpacing: 1.5
                                    font.pixelSize: 11
                                    text: MediaService.getIdentity(modelData).toUpperCase()
                                }
                                MouseArea {
                                    id: dropMouse

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onClicked: {
                                        MediaService.selectPlayer(index);
                                        playerDropdown.close();
                                    }
                                }
                            }
                        }
                    }
                }
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0   // ✅ ΝΕΟ — δεν επηρεάζει implicit width του rightCol
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
                    Layout.preferredWidth: 0   // ✅ ΝΕΟ
                    color: Theme.foreground
                    elide: Text.ElideRight
                    font.family: Theme.fontName
                    font.pixelSize: 24
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.7
                    text: MediaService.artist !== "" ? MediaService.artist : "Unknown Artist"
                }
            }
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
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: Math.max(4, root.ringOuter * 0.06)
                spacing: Math.max(14, root.ringOuter * 0.16)

                LucideIcon {
                    icon: "skip-back"
                    size: Math.max(20, root.ringOuter * 0.10)
                    color: Theme.foreground
                    opacity: btnPrev.containsMouse ? 1.0 : 0.6

                    MouseArea {
                        id: btnPrev
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: MediaService.previous()
                    }
                }
                Rectangle {
                    property real size: Math.min(65, Math.max(45, root.ringOuter * 0.35))
                    color: Theme.selected
                    height: size
                    radius: size / 2
                    scale: btnPlay.pressed ? 0.9 : 1.0
                    width: size

                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                        }
                    }

                    LucideIcon {
                        anchors.centerIn: parent
                        icon: Icons.getPlayPauseIcon(MediaService.isPlaying)
                        size: parent.width * 0.45
                        color: Theme.background
                    }

                    MouseArea {
                        id: btnPlay
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.togglePlayPause()
                    }
                }
                LucideIcon {
                    icon: "skip-forward"
                    size: Math.max(20, root.ringOuter * 0.10)
                    color: Theme.foreground
                    opacity: btnNext.containsMouse ? 1.0 : 0.6

                    MouseArea {
                        id: btnNext
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: MediaService.next()
                    }
                }
            }
        }
    }
}
