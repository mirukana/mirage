import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"

HColumnLayout {
    property int normalSpacing: 8

    HListView {
        id: memberList

        spacing: normalSpacing
        topMargin: spacing
        bottomMargin: topMargin
        Layout.leftMargin: roomSidePane.collapsed ? 0 : normalSpacing
        Layout.rightMargin: Layout.leftMargin

        Behavior on spacing {
            NumberAnimation { duration: HStyle.animationDuration }
        }

        model: chatPage.roomInfo.sortedMembers
        delegate: MemberDelegate {}

        Layout.fillWidth: true
        Layout.fillHeight: true

    }

    HTextField {
        id: filterField
        placeholderText: qsTr("Filter members")
        backgroundColor: HStyle.sidePane.filterRooms.background

        // Without this, if the user types in the field, changes of room, then
        // comes back, the field will be empty but the filter still applied.
        Component.onCompleted:
            text = Backend.clients.get(chatPage.userId).getMemberFilter(
                chatPage.category, chatPage.roomId
            )

        onTextChanged: Backend.clients.get(chatPage.userId).setMemberFilter(
            chatPage.category, chatPage.roomId, text
        )

        Layout.fillWidth: true
        Layout.preferredHeight: HStyle.bottomElementsHeight
    }
}
