import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../Base" as Base
import "utils.js" as ChatJS

Base.HGlassRectangle {
    property var typingUsers: chatPage.roomInfo.typingUsers

    color: Base.HStyle.chat.typingUsers.background

    Layout.fillWidth: true
    Layout.minimumHeight: usersLabel.text ? usersLabel.implicitHeight : 0
    Layout.maximumHeight: Layout.minimumHeight

    Base.HLabel {
        id: usersLabel
        anchors.fill: parent

        text: ChatJS.getTypingUsersText(typingUsers, chatPage.userId)
        elide: Text.ElideMiddle
        maximumLineCount: 1
    }
}
