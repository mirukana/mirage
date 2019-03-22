import QtQuick 2.7
import QtQuick.Controls 2.0

PlainLabel {
    id: text
    ToolTip {
        delay: Qt.styleHints.mousePressAndHoldInterval
        visible: text ? toolTipZone.containsMouse : false
        text: user_id
    }
    MouseArea {
        id: toolTipZone
        anchors.fill: parent
        hoverEnabled: true
    }
}
