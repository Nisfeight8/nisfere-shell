import QtQuick
import QtQuick.Controls
import qs.core
import qs.services

Rectangle {
    id: root

    anchors.fill: parent
    color: Theme.background

    Connections {
        function onNavigateToDetails() {
            mainStack.push(Qt.resolvedUrl("ContainerDetailsPage.qml"), StackView.Immediate);
        }

        target: DockerService
    }
    StackView {
        id: mainStack

        anchors.fill: parent

        initialItem: ContainerListPage {}
    }
}
