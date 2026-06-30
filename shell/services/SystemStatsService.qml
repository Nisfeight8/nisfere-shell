pragma Singleton
import QtQuick

QtObject {
    id: root

    property string cpuTempText: "0°C"
    property real cpuUsage: 0
    property string diskTotalText: "0G"
    property string diskUsage: "0%"
    property string diskUsedText: "0G"
    property string ramTotalText: "0GiB"
    property real ramUsage: 0
    property string ramUsedText: "0GiB"

    property Connections _daemon_messages: Connections {
        function onMessageReceived(type, payload) {
            if (type === "sys_stats") {
                root.cpuUsage = payload.cpuUsage;
                root.cpuTempText = payload.cpuTempText;

                root.diskTotalText = payload.diskTotalText;
                root.diskUsage = payload.diskUsage;
                root.diskUsedText = payload.diskUsedText;

                root.ramTotalText = payload.ramTotalText;
                root.ramUsage = payload.ramUsage;
                root.ramUsedText = payload.ramUsedText;
            }
        }

        target: SocketService
    }
}
