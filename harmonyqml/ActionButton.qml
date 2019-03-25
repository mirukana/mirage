import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

ToolButton {
    property string tooltip: ""
    property string iconName: ""
    property string targetPage: ""

    function toolBarIsBig() {
        return roomPane.width >
               Layout.minimumWidth * (toolBar.children.length - 2)
    }

    id: "button"
    display: ToolButton.IconOnly
    icon.source: "icons/" + iconName + ".svg"
    background: Rectangle { color: "transparent" }

    visible: toolBarIsBig()
    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.minimumWidth: height

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

        onEntered: button.background.color = "#656565"
        onExited: button.background.color = "transparent"
    }
}
