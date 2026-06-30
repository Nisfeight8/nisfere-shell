import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import qs.core
import qs.services

BaseDrawer {
    id: quakeConsole

    property var commandHistory: []
    property bool hasRunFastfetch: false
    property int historyIndex: -1

    edge: Qt.BottomEdge
    focusable: opened
    opened: ShellState.quakeTerminalOpened
    panelHeight: Screen.height / 2.3
    panelWidth: Screen.width / 2

    onCloseRequest: ShellState.quakeTerminalOpened = false
    onOpenRequest: ShellState.quakeTerminalOpened = true
    onOpenedChanged: {
        if (opened) {
            cmdInput.forceActiveFocus();
            if (!quakeConsole.hasRunFastfetch) {
                cmdProcess.write("fastfetch\n");
                quakeConsole.hasRunFastfetch = true;
            }
        }
    }
    onToggleRequest: ShellState.quakeTerminalOpened = !ShellState.quakeTerminalOpened

    ColumnLayout {
        anchors.fill: parent

        Process {
            id: cmdProcess

            command: ["python", Quickshell.shellPath("scripts/bridge_shell.py")]
            running: true
            stdinEnabled: true

            stderr: SplitParser {
                onRead: raw => {
                    outputConsole.text += raw + "\n";
                }
            }
            stdout: SplitParser {
                onRead: raw => {
                    outputConsole.text += raw + "\n";
                }
            }

            onExited: {
                outputConsole.text += "\n[Process Exited]\n";
            }
        }
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            border.color: Theme.background
            border.width: Theme.widgetBorderWidth
            color: Theme.background
            radius: Theme.radius

            ScrollView {
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                anchors.fill: parent
                anchors.margins: 10
                clip: true

                TextArea {
                    id: outputConsole

                    color: Theme.foreground
                    font.family: "Monospace"
                    font.pixelSize: 14
                    readOnly: true
                    text: "Welcome to Quickshell.\nType 'help' for available commands.\n\n"
                    wrapMode: Text.Wrap

                    background: Item {
                    }

                    onTextChanged: cursorPosition = length
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                color: Theme.selected
                font.bold: true
                font.family: "Monospace"
                font.pixelSize: 18
                text: "❯"
            }
            TextField {
                id: cmdInput

                Layout.fillWidth: true
                color: Theme.foreground
                font.family: "Monospace"
                font.pixelSize: 14
                placeholderText: "Enter command..."

                background: Item {
                }

                Keys.onDownPressed: {
                    if (quakeConsole.historyIndex < quakeConsole.commandHistory.length - 1) {
                        quakeConsole.historyIndex++;
                        text = quakeConsole.commandHistory[quakeConsole.historyIndex];
                    } else if (quakeConsole.historyIndex === quakeConsole.commandHistory.length - 1) {
                        quakeConsole.historyIndex++;
                        text = "";
                    }
                }
                Keys.onPressed: event => {
                    if (event.modifiers & Qt.ControlModifier) {
                        if (event.key === Qt.Key_C) {
                            cmdProcess.write("\x03");
                            outputConsole.text += "^C\n";
                            event.accepted = true;
                        } else if (event.key === Qt.Key_D) {
                            cmdProcess.write("\x04"); // EOF
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Z) {
                            cmdProcess.write("\x1A"); // SIGTSTP
                            outputConsole.text += "^Z\n";
                            event.accepted = true;
                        } else if (event.key === Qt.Key_L) {
                            outputConsole.text = "";
                            event.accepted = true;
                        }
                    }
                }
                Keys.onUpPressed: {
                    if (quakeConsole.commandHistory.length > 0 && quakeConsole.historyIndex > 0) {
                        quakeConsole.historyIndex--;
                        text = quakeConsole.commandHistory[quakeConsole.historyIndex];
                    }
                }
                onAccepted: {
                    let cmd = text.trim();
                    if (cmd === "")
                        return;

                    if (cmd !== "clear" && cmd !== "exit") {
                        let isPasswordPrompt = outputConsole.text.toLowerCase().includes("password");
                        if (!isPasswordPrompt) {
                            if (quakeConsole.commandHistory[quakeConsole.commandHistory.length - 1] !== cmd) {
                                quakeConsole.commandHistory.push(cmd);
                            }
                            quakeConsole.historyIndex = quakeConsole.commandHistory.length;
                            outputConsole.text += "❯ " + cmd + "\n";
                        }
                    }

                    if (cmd === "clear") {
                        outputConsole.text = "";
                    } else if (cmd === "exit") {
                        ShellState.quakeTerminalOpened = false;
                    } else {
                        cmdProcess.write(cmd + "\n");
                    }

                    text = "";
                }
            }
        }
    }
}
