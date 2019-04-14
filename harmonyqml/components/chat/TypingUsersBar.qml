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

    Base.HLabel {
        id: "usersLabel"
        anchors.fill: parent

        Timer {
            interval: 500
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: usersLabel.text = ChatJS.get_typing_users_text(
                chatPage.user_id, chatPage.room.room_id
            )
        }

        elide: Text.ElideMiddle
        maximumLineCount: 1
    }
}
