import QtQuick 2.7
import QtQuick.Controls 2.0

HLabel {
    property string toolTipText: ""

    id: text

    ToolTip {
        delay: Qt.styleHints.mousePressAndHoldInterval
        visible: text ? toolTipZone.containsMouse : false
        text: toolTipText
    }
    MouseArea {
        id: toolTipZone
        anchors.fill: parent
        hoverEnabled: true
    }
}
