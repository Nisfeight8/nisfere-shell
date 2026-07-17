import QtQuick
import QtQuick.Layouts
import qs.core

// Standard header for Control Center sub-pages: back button + title,
// with an optional trailing slot for extra controls (e.g. an enable/
// disable ToggleSwitch) declared directly as children.
// Usage:
//   PageHeader {
//       Layout.fillWidth: true
//       title: "Wi-Fi"
//       onBackRequested: pageStack.currentIndex = 0
//
//       ToggleSwitch {
//           checked: NetworkService.wifiEnabled
//           onToggled: NetworkService.wifi.toggle()
//       }
//   }
RowLayout {
    id: root

    property string title: ""
    signal backRequested

    // Extra children declared inside PageHeader{} land here, after the title.
    default property alias trailingData: trailingRow.data

    spacing: 10

    IconButton {
        icon: "chevron-left"
        size: 32
        iconSize: 18
        normalColor: Theme.backgroundAlt
        onTapped: root.backRequested()
    }

    PageTitle {
        Layout.fillWidth: true
        text: root.title
        elide: Text.ElideRight
    }

    RowLayout {
        id: trailingRow
        spacing: 8
    }
}
