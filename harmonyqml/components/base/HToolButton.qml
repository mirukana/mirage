import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

ToolButton {
    property string tooltip: ""
    property string iconName: ""

    id: "button"
    display: ToolButton.IconOnly
    icon.source: "../../icons/" + iconName + ".svg"
    background: Rectangle { color: "transparent" }

    onClicked: toolTip.hide()

    ToolTip {
        id: toolTip
        text: tooltip
        delay: Qt.styleHints.mousePressAndHoldInterval
        visible: text ? toolTipZone.containsMouse : false
    }
    MouseArea {
        id: "toolTipZone"
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // Make button receive clicks normally

        onEntered: button.background.color = "#656565"
        onExited: button.background.color = "transparent"
    }
}
