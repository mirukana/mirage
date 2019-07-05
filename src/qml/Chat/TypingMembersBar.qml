import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

HRectangle {
    color: HStyle.chat.typingMembers.background

    Layout.fillWidth: true
    Layout.preferredHeight: usersLabel.text ? usersLabel.implicitHeight : 0

    HLabel {
        id: usersLabel
        anchors.fill: parent

        text: chatPage.roomInfo.typingText
        elide: Text.ElideMiddle
        maximumLineCount: 1
    }
}
