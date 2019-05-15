import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"

HColumnLayout {
    property int normalSpacing: 8

    Layout.leftMargin: roomSidePane.collapsed ? 0 : normalSpacing
    Layout.rightMargin: Layout.leftMargin

    HListView {
        id: memberList

        spacing: parent.Layout.leftMargin
        topMargin: spacing
        bottomMargin: topMargin

        Behavior on spacing {
            NumberAnimation { duration: HStyle.animationDuration }
        }

        model: chatPage.roomInfo.sortedMembers
        delegate: MemberDelegate {}

        Layout.fillWidth: true
        Layout.fillHeight: true

    }
}
