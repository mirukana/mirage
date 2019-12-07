import QtQuick 2.12
import QtQuick.Controls 2.12

Popup {
    id: popup
    anchors.centerIn: Overlay.overlay
    modal: true
    focus: true
    padding: 0
    margins: theme.spacing


    enter: Transition {
        HScaleAnimator { from: 0; to: 1; overshoot: 4 }
    }

    exit: Transition {
        // FIXME: HScaleAnimator won't work here?
        HNumberAnimation { property: "scale"; to: 0 }
    }

    background: Rectangle {
        color: theme.controls.popup.background
    }
}
