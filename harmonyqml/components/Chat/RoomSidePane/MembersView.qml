import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"

Column {
    property int normalSpacing: 8
    property bool collapsed:
        width < roomSidePane.Layout.minimumWidth + normalSpacing

    leftPadding: collapsed ? 0 : normalSpacing
    rightPadding: leftPadding

    ListView {
        width: parent.width
        height: parent.height

        id: memberList

        spacing: collapsed ? 0 : normalSpacing
        topMargin: spacing
        bottomMargin: topMargin

        Behavior on spacing {
            NumberAnimation { duration: 150 }
        }

        model: chatPage.roomInfo.members
        delegate: MemberDelegate {}
    }
}
