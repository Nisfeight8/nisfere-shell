pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QMLTermWidget
import qs.core
import qs.services

BaseDrawer {
    id: terminalRoot
    z: 10
    preload: true
    edge: Qt.BottomEdge
    openedRequest: ShellState.terminalOpened
    minPanelHeight: 550 * Theme.scaleFor(screen)
    minPanelWidth: screen.width / 1.1 * Theme.scaleFor(screen)
    toggleOnHover: true
    onCloseRequest: ShellState.terminalOpened = false

    contentComponent: Component {
        Rectangle {
            id: contentRoot

            Action {
                onTriggered: terminal.copyClipboard()
                shortcut: "Ctrl+Shift+C"
            }

            Action {
                onTriggered: terminal.pasteClipboard()
                shortcut: "Ctrl+Shift+V"
            }

            Action {
                onTriggered: searchButton.visible = !searchButton.visible
                shortcut: "Ctrl+F"
            }

            Action {
                onTriggered: {
                    console.log('open new terminal window in:' + mainsession.currentDir);
                }
                shortcut: "Ctrl+Shift+T"
            }

            // No inner reload Loader anymore — the actual bug (C++
            // TerminalDisplay::setColorScheme gating every lookup on
            // a once-ever-cached availableColorSchemes() list) is
            // fixed at the source now (see nisfere's qmltermwidget
            // fork), so the colorScheme binding below just reacts
            // correctly on its own. A nice side benefit over the old
            // workaround: the live shell session now survives theme
            // changes too, not just ordinary open/close.
            QMLTermWidget {
                id: terminal
                anchors.fill: parent
                // Was Theme.fontName — that's the shell's UI font,
                // proportional/variable-width (hence the "Using a
                // variable-width font in the terminal" warning and
                // broken character-grid alignment). A terminal needs
                // an actual fixed-width font; this is a technical
                // requirement, not a style choice, so it's
                // deliberately NOT tied to the shell's theme font.
                // Plain "monospace" is a generic Qt alias that always
                // resolves to some real monospace font on any system.
                // If you want nerd-font glyphs inside the terminal
                // itself (prompt icons etc.), swap this for a specific
                // monospace nerd font you have installed — look for
                // the "Mono" suffixed variant specifically (e.g.
                // "JetBrainsMono Nerd Font Mono"), since the
                // non-"Mono" default variants of some nerd fonts can
                // include double-width glyphs that break alignment
                // the same way a proportional font does.
                font.family: "monospace"
                font.pointSize: 12
                colorScheme: ThemeState.terminalColorScheme !== "" ? ThemeState.terminalColorScheme : "cool-retro-term"

                session: QMLTermSession {
                    id: mainsession
                    initialWorkingDirectory: "$HOME"
                }
                Component.onCompleted: {
                    mainsession.startShellProgram();
                    if (terminalRoot.opened)
                        terminal.forceActiveFocus();
                }

                // QMLTermScrollbar {
                //     terminal: terminal
                //     width: 20
                //     Rectangle {
                //         opacity: 0.4
                //         anchors.margins: 5
                //         radius: width * 0.5
                //         anchors.fill: parent
                //     }
                // }
            }

            // Button {
            //     id: searchButton
            //     text: "Find version"
            //     anchors.bottom: parent.bottom
            //     anchors.right: parent.right
            //     visible: false
            //     onClicked: mainsession.search("version")
            // }

            // Re-focuses every time the drawer is actually shown —
            // still needed since preload keeps this content alive
            // across close/reopen (Component.onCompleted only fires
            // once, at initial creation).
            Connections {
                target: terminalRoot
                function onOpenedChanged() {
                    if (terminalRoot.opened)
                        terminal.forceActiveFocus();
                }
            }
        }
    }
}
