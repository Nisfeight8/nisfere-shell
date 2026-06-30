pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property Socket clientSocket: Socket {
        id: clientSocketId

        connected: true
        path: "/tmp/nisfere-shell.sock"

        parser: SplitParser {
            onRead: message => {
                try {
                    let data = JSON.parse(message);
                    root.messageReceived(data.type, data.payload);
                } catch (e) {
                    console.log("Socket Service JSON Error:", e);
                }
            }
        }

        onConnectedChanged: {
            if (!connected) {
                console.log("Lost connection to daemon. Retrying...");
                reconnectTimer.start();
            } else {
                console.log("Connected to Nisfere Daemon!");
                reconnectTimer.stop();
            }
        }
    }
    property Timer reconnectTimer: Timer {
        id: reconnectTimer

        interval: 1000
        repeat: true
        running: false

        onTriggered: {
            if (!clientSocketId.connected) {
                clientSocketId.connected = true;
            }
        }
    }

    signal messageReceived(string type, var payload)

    function sendCommand(moduleName, action, payload = {}) {
        if (clientSocketId.connected) {
            let data = Object.assign({
                "module": moduleName,
                "action": action,
                "payload": payload
            });

            let msg = JSON.stringify(data) + "\n";
            clientSocketId.write(msg);
            clientSocketId.flush();
        }
    }
}
