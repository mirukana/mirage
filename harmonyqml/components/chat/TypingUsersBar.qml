import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base
import "utils.js" as ChatJS

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.minimumHeight: usersLabel.text ? usersLabel.implicitHeight : 0
    Layout.maximumHeight: Layout.minimumHeight
    color: "#BBB"

    property var typingUsers: chatPage.roomInfo.typingUsers

    Base.HLabel {
        id: usersLabel
        anchors.fill: parent
        text: ChatJS.getTypingUsersText(typingUsers, chatPage.userId)

        elide: Text.ElideMiddle
        maximumLineCount: 1
    }
}
