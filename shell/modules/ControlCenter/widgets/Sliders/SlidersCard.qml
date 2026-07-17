import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import "widgets"

GlassCard {
    Layout.fillWidth: true

    // implicitHeight (όχι height!) ← ColumnLayout το χρειάζεται για layout
    // +30 = 15 (top margin) + 15 (bottom margin)
    implicitHeight: slidersColumn.implicitHeight + 30

    ColumnLayout {
        id: slidersColumn
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        Volume {
            Layout.fillWidth: true
        }

        Mic {
            id: mic
            Layout.fillWidth: true
        }

        Loader {
            active: BrightnessService.isAvailable
            // NOTE: `visible` matches `active` here — without it, an
            // inactive Loader (0 height) still counts as a ColumnLayout
            // child and still gets a `spacing: 15` gap reserved around
            // it, adding a phantom 15px at the bottom on machines
            // without brightness control (desktops). Setting visible
            // false too excludes it from the layout entirely, matching
            // how invisible items are always skipped by Row/ColumnLayout.
            visible: BrightnessService.isAvailable
            asynchronous: true
            source: "widgets/Brightness.qml"
            Layout.fillWidth: true
            Layout.preferredHeight: BrightnessService.isAvailable ? mic.implicitHeight : 0
            //                                                       ↑ implicitHeight όχι height
        }
    }
}
