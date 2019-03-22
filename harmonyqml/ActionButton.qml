import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

ToolButton {
    property string tooltip: ""
    property string iconName: ""
    property string targetPage: ""

    id: "root"
    width: parent.width / parent.children.length
    height: parent.height
    display: ToolButton.IconOnly
    icon.source: "icons/" + iconName + ".svg"
    background: Rectangle { color: "transparent" }

    onClicked: { toolTip.hide(); pageStack.show_page(targetPage) }

    ToolTip {
        id: "toolTip"
        text: tooltip
        delay: Qt.styleHints.mousePressAndHoldInterval
        visible: text ? toolTipZone.containsMouse : false
    }
    MouseArea {
        id: toolTipZone
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // Make button receive clicks normally

        onEntered: root.background.color = "#656565"
        onExited: root.background.color = "transparent"
    }
}
