import QtQuick 2.12
import QtQuick.Controls 2.12

ToolTip {
    // Be sure to have a width and height set, to prevent the tooltip from
    // going out of the window's boundaries

    id: toolTip
    delay: Qt.styleHints.mousePressAndHoldInterval
    padding: 0

    enter: Transition {
        HNumberAnimation { property: "opacity"; from: 0.0; to: 1.0 }
    }
    exit: Transition {
        HNumberAnimation { property: "opacity"; from: 1.0; to: 0.0 }
    }

    TapHandler {
        onTapped: { toolTip.hide() }
    }
}
