pragma Singleton
import QtQuick
import qs.services

QtObject {
    id: root

    // ── CPU ───────────────────────────────────────────────────────
    property real cpuUsage: 0.0
    property string cpuTempText: "0°C"

    // ── RAM ───────────────────────────────────────────────────────
    property real ramUsage: 0.0
    property string ramUsedText: "0GiB"
    property string ramTotalText: "0GiB"

    // ── Disk ──────────────────────────────────────────────────────
    property string diskUsage: "0%"
    property string diskUsedText: "0G"
    property string diskTotalText: "0G"

    // ── Network ───────────────────────────────────────────────────
    property string netDownText: "0 B/s"
    property string netUpText: "0 B/s"
    property real netDownMbps: 0.0
    property real netUpMbps: 0.0

    // ── Daemon message handler ────────────────────────────────────
    property Connections _conn: Connections {
        target: SocketService

        function onMessageReceived(type, payload) {
            if (type !== "sys_stats")
                return;
            root.cpuUsage = payload.cpuUsage ?? 0;
            root.cpuTempText = payload.cpuTempText ?? "N/A";
            root.ramUsage = payload.ramUsage ?? 0;
            root.ramUsedText = payload.ramUsedText ?? "0GiB";
            root.ramTotalText = payload.ramTotalText ?? "0GiB";
            root.diskUsage = payload.diskUsage ?? "0%";
            root.diskUsedText = payload.diskUsedText ?? "0G";
            root.diskTotalText = payload.diskTotalText ?? "0G";
            root.netDownText = payload.netDownText ?? "0 B/s";
            root.netUpText = payload.netUpText ?? "0 B/s";
            root.netDownMbps = payload.netDownMbps ?? 0;
            root.netUpMbps = payload.netUpMbps ?? 0;
        }
    }
}
