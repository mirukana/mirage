import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

ColumnLayout {
    property string userId: ""
    property string roomId: ""

    readonly property var roomInfo:
        Backend.models.rooms.get(userId).getWhere("roomId", roomId)

    property bool isInvite: roomInfo.category === "Invites"

    id: chatPage
    spacing: 0
    onFocusChanged: sendBox.setFocus()

    RoomHeader {
        displayName: roomInfo.displayName
        topic: roomInfo.topic
    }


    MessageList {}


    TypingUsersBar {}

    InviteOffer {
        visible: isInvite
    }

    SendBox {
        id: sendBox
        visible: ! isInvite
    }
}
