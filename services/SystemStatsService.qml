pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property FileView _cpuFile: FileView {
        path: "/proc/stat"
    }
    property Process _diskProc: Process {
        command: ["df", "-h", "/"]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length > 1) {
                    let parts = lines[1].replace(/\s+/g, " ").split(" ");
                    if (parts.length >= 5) {
                        root.diskTotalText = parts[1];
                        root.diskUsedText = parts[2];
                        root.diskUsage = parts[4];
                    }
                }
            }
        }
    }
    property Timer _fastTimer: Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            _memFile.reload();
            _cpuFile.reload();
            _tempFile.reload();

            root.updateRam();
            root.updateCpu();
            root.updateTemp();
        }
    }
    property Process _findTempProc: Process {
        command: ["sh", "-c", "grep -lE 'coretemp|k10temp|zenpower' /sys/class/hwmon/hwmon*/name 2>/dev/null | head -n 1 | sed 's/name/temp1_input/'"]

        stdout: StdioCollector {
            onStreamFinished: {
                let foundPath = this.text.trim();
                if (foundPath !== "") {
                    root.tempPath = foundPath;
                    _tempFile.reload();
                    root.updateTemp();
                } else {
                    root.cpuTempText = "N/A";
                    console.error("SystemStats: No temperature sensor was found CPU!");
                }
            }
        }
    }
    property FileView _memFile: FileView {
        path: "/proc/meminfo"
    }
    property real _prevIdle: 0
    property real _prevTotal: 0
    property Timer _slowTimer: Timer {
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            _diskProc.exec(["df", "-h", "/"]);
        }
    }
    property FileView _tempFile: FileView {
        path: tempPath
    }
    property string cpuTempText: "0°C"
    property real cpuUsage: 0
    property string diskTotalText: "0G"
    property string diskUsage: "0%"
    property string diskUsedText: "0G"
    property string ramTotalText: "0GiB"
    property real ramUsage: 0
    property string ramUsedText: "0GiB"
    property string tempPath: ""

    function updateCpu() {
        let text = _cpuFile.text();
        if (!text)
            return;

        let cpuLine = text.split("\n")[0];
        let parts = cpuLine.replace(/\s+/g, " ").trim().split(" ");
        if (parts.length < 5)
            return;

        let user = parseInt(parts[1]), nice = parseInt(parts[2]), system = parseInt(parts[3]);
        let idle = parseInt(parts[4]), iowait = parseInt(parts[5]), irq = parseInt(parts[6]);
        let softirq = parseInt(parts[7]), steal = parseInt(parts[8]);

        let totalIdle = idle + iowait;
        let totalNonIdle = user + nice + system + irq + softirq + steal;
        let total = totalIdle + totalNonIdle;

        let diffTotal = total - root._prevTotal;
        let diffIdle = totalIdle - root._prevIdle;

        if (diffTotal > 0) {
            root.cpuUsage = (diffTotal - diffIdle) / diffTotal;
        }

        root._prevTotal = total;
        root._prevIdle = totalIdle;
    }
    function updateRam() {
        let text = _memFile.text();
        if (!text)
            return;

        let totalMatch = text.match(/MemTotal:\s+(\d+)/);
        let availMatch = text.match(/MemAvailable:\s+(\d+)/);

        if (totalMatch && availMatch) {
            let totalKb = parseInt(totalMatch[1]);
            let availKb = parseInt(availMatch[1]);
            let usedKb = totalKb - availKb;

            root.ramUsage = usedKb / totalKb;
            root.ramUsedText = (usedKb / 1048576).toFixed(1) + "GiB";
            root.ramTotalText = (totalKb / 1048576).toFixed(1) + "GiB";
        }
    }
    function updateTemp() {
        if (root.tempPath === "")
            return;

        let text = _tempFile.text();
        if (!text)
            return;

        let millidegrees = parseInt(text.trim());
        if (!isNaN(millidegrees)) {
            let celsius = Math.round(millidegrees / 1000);
            root.cpuTempText = celsius + "°C";
        }
    }

    Component.onCompleted: {
        _findTempProc.running = true;
    }
}
