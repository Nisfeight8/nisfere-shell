import QtQuick

Loader {
    id: root

    property Component sourceComp
    property bool isComplete
    property bool _waitingForLoad: false

    onSourceCompChanged: {
        if (isComplete) {
            // Αν πατήσει γρήγορα άλλο tab ενώ ήδη φεύγει το προηγούμενο,
            // απλά πάμε την opacity στο 0 κατευθείαν και φορτώνουμε το νέο.
            fadeInAnim.stop();
            if (anim.running) {
                anim.stop();
                opacity = 0;
                _waitingForLoad = true;
                sourceComponent = sourceComp;
            } else {
                anim.restart();
            }
        }
    }
    asynchronous: true

    onStatusChanged: {
        if (status === Loader.Ready && _waitingForLoad) {
            _waitingForLoad = false;
            fadeInAnim.start();
        }
    }

    Component.onCompleted: {
        isComplete = true;
        sourceComponent = sourceComp;
    }

    SequentialAnimation {
        id: anim
        NumberAnimation {
            target: root
            property: "opacity"
            to: 0
            easing.type: Easing.Bezier
            duration: 150
        }
        ScriptAction {
            script: {
                root._waitingForLoad = true;
                root.sourceComponent = root.sourceComp;
            }
        }
    }

    NumberAnimation {
        id: fadeInAnim
        target: root
        property: "opacity"
        to: 1
        easing.type: Easing.Bezier
        duration: 200
    }
}
