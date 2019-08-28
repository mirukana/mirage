import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

Rectangle {
    id: roomSidePane
    color: theme.chat.roomSidePane.background

    property bool collapsed: false
    property var activeView: null
    property int currentSpacing: collapsed ? 0 : theme.spacing

    Behavior on currentSpacing { HNumberAnimation {} }

    MembersView {
        anchors.fill: parent
    }
}
