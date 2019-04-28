import QtQuick 2.7
import QtQuick.Layouts 1.0
import "../Base"
import "utils.js" as ChatJS

HGlassRectangle {
    property var typingUsers: chatPage.roomInfo.typingUsers

    color: HStyle.chat.typingUsers.background

    Layout.fillWidth: true
    Layout.minimumHeight: usersLabel.text ? usersLabel.implicitHeight : 0
    Layout.maximumHeight: Layout.minimumHeight

    HLabel {
        id: usersLabel
        anchors.fill: parent

        text: ChatJS.getTypingUsersText(typingUsers, chatPage.userId)
        elide: Text.ElideMiddle
        maximumLineCount: 1
    }
}
