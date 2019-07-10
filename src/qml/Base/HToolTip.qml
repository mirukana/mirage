import QtQuick 2.7
import QtQuick.Controls 2.0

ToolTip {
    delay: Qt.styleHints.mousePressAndHoldInterval

    enter: Transition {
        HNumberAnimation { property: "opacity"; from: 0.0; to: 1.0 }
    }
    exit: Transition {
        HNumberAnimation { property: "opacity"; from: 1.0; to: 0.0 }
    }
}
