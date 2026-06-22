import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.core
import qs.services
import "widgets"

GridLayout {
    Layout.fillWidth: true
    columnSpacing: 15
    columns: 2
    rowSpacing: 15

    Ethernet {
    }
    Wifi {
    }
    Bluetooth {
    }
    Dnd {
    }
    NightLight {
    }
    PowerProfile {
    }
}
