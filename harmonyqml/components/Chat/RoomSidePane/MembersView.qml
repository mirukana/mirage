import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"

Column {
    property int normalSpacing: 8

    leftPadding: roomSidePane.collapsed ? 0 : normalSpacing
    rightPadding: leftPadding

    ListView {
        width: parent.width
        height: parent.height

        id: memberList

        spacing: parent.leftPadding
        topMargin: spacing
        bottomMargin: topMargin

        Behavior on spacing {
            NumberAnimation { duration: 120 }
        }

        model: chatPage.roomInfo.members
        delegate: MemberDelegate {}
    }
}
