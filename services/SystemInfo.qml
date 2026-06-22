pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: sysInfo

    property FileView _osReleaseFile: FileView {
        blockLoading: true
        path: "/etc/os-release"
    }

    property FileView _uptimeFile: FileView {
        path: "/proc/uptime"
    }
    property Timer _uptimeTimer: Timer {
        interval: 60000 // 1 minute
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            _uptimeFile.reload();

            let content = _uptimeFile.text().trim();
            if (content) {
                let seconds = parseFloat(content.split(" ")[0]);
                uptime = formatUptime(seconds);
            }
        }
    }
    property string osName: "Loading..."
    property string uptime: "Loading..."
    property string username: Quickshell.env("USER") || "Unknown"
    property string windowManager: Quickshell.env("XDG_CURRENT_DESKTOP") || "Unknown"

    function formatUptime(totalSeconds) {
        let days = Math.floor(totalSeconds / 86400);
        let hours = Math.floor((totalSeconds % 86400) / 3600);
        let minutes = Math.floor((totalSeconds % 3600) / 60);

        let parts = [];
        if (days > 0)
            parts.push(days + (days === 1 ? " day" : " days"));
        if (hours > 0)
            parts.push(hours + (hours === 1 ? " hour" : " hours"));
        parts.push(minutes + (minutes === 1 ? " minute" : " minutes"));

        return "up " + parts.join(", ");
    }

    Component.onCompleted: {
        var content = _osReleaseFile.text();
        var match = content.match(/PRETTY_NAME="([^"]+)"/);
        osName = match ? match[1] : "Unknown";
    }
}
