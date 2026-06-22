pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property FileView _currentFile: FileView {
        path: root.backlightPath !== "" ? root.backlightPath + "/actual_brightness" : ""

        onTextChanged: {
            let val = parseInt(text.trim());
            if (!isNaN(val))
                root.currentBrightness = val;
        }
    }
    property Process _detect_device: Process {
        id: backlightProcess

        stdout: StdioCollector {
            onStreamFinished: {
                let devName = text.trim();

                if (devName !== "") {
                    root.backlightPath = "/sys/class/backlight/" + devName;
                    console.log("Found Backlight:", root.backlightPath);
                } else {
                    console.warn("No display brightness control found.");
                }
            }
        }

        Component.onCompleted: {
            exec(["ls", "/sys/class/backlight"]);
        }
    }
    property FileView _maxFile: FileView {
        path: root.backlightPath !== "" ? root.backlightPath + "/max_brightness" : ""

        onTextChanged: {
            let val = parseInt(text.trim());
            if (!isNaN(val))
                root.maxBrightness = val;
        }
    }
    property Timer _updateTimer: Timer {
        interval: 1000
        repeat: true
        running: root.isAvailable

        onTriggered: root._currentFile.reload()
    }
    property string backlightPath: ""
    property real currentBrightness: 0
    property bool isAvailable: backlightPath !== ""
    property real maxBrightness: 100
    property real percentage: maxBrightness > 0 ? (currentBrightness / maxBrightness) : 0

    function setPercentage(val) {
        if (!isAvailable)
            return;

        let percentInt = Math.round(val * 100);

        if (percentInt < 5)
            percentInt = 5;

        Quickshell.execDetached(["brightnessctl", "s", percentInt + "%"]);

        root.currentBrightness = root.maxBrightness * val;
    }
}
