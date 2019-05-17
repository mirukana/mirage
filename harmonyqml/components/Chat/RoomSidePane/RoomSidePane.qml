import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"

HRectangle {
    id: roomSidePane

    property bool collapsed: false
    property var activeView: null

    MembersView {
        anchors.fill: parent
        collapsed: parent.collapsed
    }
}
