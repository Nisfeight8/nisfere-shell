import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Wayland
import qs.core
import qs.services

WlSessionLock {
    id: sessionLock
    locked: ShellState.isLocked

    WlSessionLockSurface {
        color: "black"

        Connections {
            target: LockerService

            function onUnlocked() {
                ShellState.isLocked = false;
            }

            function onFailed(errorMessage) {
                lockContainer.isAuthenticating = false;
                passwordInput.text = "";
                errorText.text = errorMessage;
                errorText.opacity = 1;
                // Was a direct `passwordInput.background.border.color =
                // Theme.color1` assignment — that PERMANENTLY destroys
                // the declarative binding on border.color (imperative
                // assignment to an already-bound property replaces the
                // binding with a static value forever). Every "restore"
                // afterward was then just another one-off static value,
                // never a real binding again — so after the FIRST failed
                // attempt, the border would never again reactively
                // follow focus changes. Now driven by a plain state flag
                // instead, with the actual color logic staying inside
                // the background Rectangle's own binding, permanently.
                passwordInput.hasError = true;
                passwordInput.forceActiveFocus();
                errorTimer.restart();
            }
        }

        Timer {
            id: errorTimer
            interval: 2500
            onTriggered: {
                errorText.opacity = 0;
                passwordInput.hasError = false;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: passwordInput.forceActiveFocus()
        }

        Image {
            anchors.fill: parent
            source: Theme.wallpaper
            fillMode: Image.PreserveAspectCrop
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.5
        }

        Item {
            id: lockContainer
            anchors.fill: parent
            focus: true

            property bool isAuthenticating: false

            Keys.onEscapePressed: {
                passwordInput.text = "";
                errorText.opacity = 0;
                errorTimer.stop();
                passwordInput.hasError = false;
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 40

                // --- Clock & Date ---
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 0

                    Text {
                        id: clockText
                        Layout.alignment: Qt.AlignHCenter
                        font.family: Theme.fontName
                        font.pixelSize: 100
                        font.bold: true
                        color: "white"

                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm")
                        }
                        Component.onCompleted: text = Qt.formatDateTime(new Date(), "HH:mm")
                    }

                    Text {
                        id: dateText
                        Layout.alignment: Qt.AlignHCenter
                        font.family: Theme.fontName
                        font.pixelSize: 20
                        color: "white"
                        opacity: 0.7

                        Timer {
                            interval: 60000
                            running: true
                            repeat: true
                            onTriggered: dateText.text = Qt.formatDate(new Date(), "dddd, d MMMM")
                        }
                        Component.onCompleted: text = Qt.formatDate(new Date(), "dddd, d MMMM")
                    }
                }

                // --- User Info & Auth ---
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20

                    Rectangle {
                        id: avatarBadge
                        width: 100
                        height: 100
                        radius: 50
                        color: Theme.backgroundAlt
                        border.color: Theme.borderColor
                        border.width: 2
                        clip: true
                        Layout.alignment: Qt.AlignHCenter

                        // Same pattern as SystemDrawerHeader.qml — reads
                        // from the shared scope's avatarPath setting,
                        // falls back to the generic user icon if unset.
                        readonly property string _avatarSource: ThemeState.shared.avatarPath ? "file://" + ThemeState.shared.avatarPath : ""

                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: avatarBadge._avatarSource
                            visible: avatarBadge._avatarSource !== ""
                        }

                        LucideIcon {
                            anchors.centerIn: parent
                            icon: "user"
                            size: 50
                            color: Theme.foreground
                            visible: avatarBadge._avatarSource === ""
                        }
                    }

                    Text {
                        text: SystemInfo.username
                        font.family: Theme.fontName
                        font.pixelSize: 24
                        font.bold: true
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Input + Loader σε κοινό Item
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 260
                        Layout.preferredHeight: 46

                        TextField {
                            id: passwordInput
                            // Was commented out — meant the field stayed
                            // fully enabled (and visible) WHILE a
                            // previous authentication attempt was still
                            // in flight, so you could mash Enter and
                            // fire off overlapping auth calls.
                            property bool hasError: false

                            anchors.fill: parent
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            // Native placeholderText wasn't rendering
                            // reliably in this surface (possibly a race
                            // with forceActiveFocus() firing immediately
                            // on completion, unlike WifiPage's password
                            // field which only gets focus after a user
                            // interaction) — using our own overlay Text
                            // instead, same idiom as Tasks.qml's add-task
                            // input placeholder.
                            placeholderText: ""
                            color: Theme.foreground
                            font.family: Theme.fontName
                            font.pixelSize: 16
                            horizontalAlignment: TextInput.AlignHCenter
                            enabled: !lockContainer.isAuthenticating

                            background: Rectangle {
                                color: Theme.backgroundAlt
                                radius: Theme.radius
                                // Now a single, permanent declarative
                                // binding covering both error and focus
                                // state — nothing ever assigns to this
                                // imperatively, so it can never break.
                                border.color: passwordInput.hasError ? Theme.color1 : (passwordInput.activeFocus ? Theme.selected : Theme.borderColor)
                                border.width: 2

                                Behavior on border.color {
                                    AnimColor {
                                        type: Anim.FastEffects
                                    }
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                height: 20
                                color: "transparent"
                                radius: 10

                                border.color: Theme.selected
                                border.width: 3

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 3
                                    height: 3
                                    color: Theme.foreground
                                    radius: 2
                                }

                                RotationAnimation on rotation {
                                    running: lockContainer.isAuthenticating
                                    loops: Animation.Infinite
                                    from: 0
                                    to: 360
                                    duration: 800
                                }

                                visible: lockContainer.isAuthenticating
                            }
                            onAccepted: {
                                if (text.length === 0)
                                    return;
                                lockContainer.isAuthenticating = true;
                                errorText.opacity = 0;
                                LockerService.authenticate(text);
                            }

                            Component.onCompleted: forceActiveFocus()

                            Text {
                                anchors.centerIn: parent
                                text: "Enter password..."
                                color: Qt.rgba(1, 1, 1, 0.4)
                                font.family: Theme.fontName
                                font.pixelSize: 16
                                visible: passwordInput.text.length === 0
                            }
                        }
                    }

                    Text {
                        id: errorText
                        Layout.alignment: Qt.AlignHCenter
                        color: Theme.color1
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        opacity: 0
                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }

                    // --- Power actions (reboot / suspend / poweroff) ──
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 10
                        spacing: 16

                        CircularActionButton {
                            icon: "rotate-ccw"
                            label: "Restart"
                            onTapped: PowerService.reboot()
                        }
                        CircularActionButton {
                            icon: "moon"
                            label: "Suspend"
                            onTapped: PowerService.suspend()
                        }
                        CircularActionButton {
                            icon: "power"
                            label: "Shut Down"
                            onTapped: PowerService.poweroff()
                        }
                    }
                }
            }

            // --- Footer Widgets ---
            RowLayout {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 60
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24

                // Weather Widget
                Rectangle {
                    width: 130
                    height: 54
                    radius: Theme.radius
                    color: Theme.backgroundAlt
                    opacity: 0.9

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        LucideIcon {
                            icon: "cloud"
                            size: 20
                            color: Theme.foreground
                        }
                        Text {
                            text: Math.round(WeatherService.temperature) + "°C"
                            font.family: Theme.fontName
                            font.pixelSize: 16
                            color: Theme.foreground
                        }
                    }
                }

                // Media Widget
                Rectangle {
                    visible: MediaService.hasPlayer
                    width: 280
                    height: 54
                    radius: Theme.radius
                    color: Theme.backgroundAlt
                    opacity: 0.9

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        LucideIcon {
                            icon: "music"
                            size: 18
                            color: Theme.selected
                        }

                        Text {
                            Layout.fillWidth: true
                            text: MediaService.title
                            font.family: Theme.fontName
                            font.pixelSize: 13
                            color: Theme.foreground
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            spacing: 12
                            LucideIcon {
                                icon: "skip-back"
                                size: 18
                                color: Theme.foreground

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    onTapped: MediaService.previous()
                                }
                            }
                            LucideIcon {
                                icon: MediaService.isPlaying ? "pause" : "play"
                                size: 18
                                color: Theme.foreground

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    onTapped: MediaService.togglePlayPause()
                                }
                            }
                            LucideIcon {
                                icon: "skip-forward"
                                size: 18
                                color: Theme.foreground

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    onTapped: MediaService.next()
                                }
                            }
                        }
                    }
                }

                // Keyboard Layout Widget
                Rectangle {
                    width: 100
                    height: 54
                    radius: Theme.radius
                    color: Theme.backgroundAlt
                    opacity: 0.9

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        LucideIcon {
                            icon: "keyboard"
                            size: 18
                            color: Theme.foreground
                        }
                        Text {
                            text: KeyboardService.currentLayout.toUpperCase()
                            font.family: Theme.fontName
                            font.pixelSize: 16
                            font.bold: true
                            color: Theme.foreground
                        }
                    }
                }
            }
        }
    }
}
