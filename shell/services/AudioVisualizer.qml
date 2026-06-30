pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property Process _cavaProc: Process {
        id: cava

        command: ["cava", "-p", Quickshell.shellPath("assets/cava.conf")]
        running: root.isActive

        stdout: SplitParser {
            onRead: data => {
                let rawValues = data.trim().split(";").filter(v => v !== "");

                if (rawValues.length === 0)
                    return;

                let currentBars = rawValues.map(v => Number(v));
                let barCount = currentBars.length;

                if (barCount === 0)
                    return;

                let bassSum = 0;
                let totalSum = 0;
                let bassCount = Math.min(3, barCount);

                for (let i = 0; i < barCount; i++) {
                    let val = currentBars[i];
                    totalSum += val;
                    if (i < bassCount) {
                        bassSum += val;
                    }
                }

                root.bars = currentBars;
                root.bass = bassSum / bassCount;
                root.level = totalSum / barCount;
            }
        }
    }
    property var bars: []
    property real bass: 0
    property bool isActive: MediaService.isPlaying
    property real level: 0

    onIsActiveChanged: {
        if (!isActive) {
            root.bars = [];
            root.bass = 0;
            root.level = 0;
        }
    }
}
