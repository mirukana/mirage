import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

ColumnLayout {
    property var user_id: null
    property var room: null


    id: chatPage
    spacing: 0
    onFocusChanged: sendBox.setFocus()

    RoomHeader {}
    MessageList {}
    TypingUsersBar {}
    SendBox { id: sendBox }
}
