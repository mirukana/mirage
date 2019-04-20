import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

ColumnLayout {
    property var userId: null
    property var roomId: null

    property var roomInfo:
        Backend.models.rooms.get(userId).getWhere("roomId", roomId)

    id: "chatPage"
    spacing: 0
    onFocusChanged: sendBox.setFocus()

    RoomHeader {
        id: "roomHeader"
        displayName: roomInfo.displayName
        topic: roomInfo.topic
    }

    MessageList {}
    TypingUsersBar {}
    SendBox { id: "sendBox" }
}
