import QtQuick 2.12
import QtQuick.Controls 2.12

Popup {
    id: popup
    anchors.centerIn: Overlay.overlay
    modal: true
    focus: true
    padding: 0


    default property alias boxData: box.body
    property alias box: box


    enter: Transition {
        HNumberAnimation { property: "scale"; from: 0; to: 1; overshoot: 4 }
    }

    exit: Transition {
        HNumberAnimation { property: "scale"; to: 0 }
    }

    background: Rectangle {
        color: theme.controls.popup.background
    }

    contentItem: HBox {
        id: box
        implicitWidth: theme.minimumSupportedWidthPlusSpacing
    }
}
