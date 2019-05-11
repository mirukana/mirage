import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"
import "utils.js" as ChatJS

HGlassRectangle {
    property var typingMembers: chatPage.roomInfo.typingMembers

    color: HStyle.chat.typingMembers.background

    Layout.fillWidth: true
    Layout.minimumHeight: usersLabel.text ? usersLabel.implicitHeight : 0
    Layout.maximumHeight: Layout.minimumHeight

    HLabel {
        id: usersLabel
        anchors.fill: parent

        text: ChatJS.getTypingMembersText(typingMembers, chatPage.userId)
        elide: Text.ElideMiddle
        maximumLineCount: 1
    }
}
