import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

Banner {
    property var inviter: null

    avatarName: inviter ? inviter.displayname : ""
    //avatarSource: inviter ? inviter.avatar_url : ""

    labelText:
        (inviter ?
         ("<b>" + inviter.displayname + "</b>") : qsTr("Someone")) +
        " " + qsTr("invited you to join the room.")

    buttonModel: [
        {
            text: "Accept",
            iconName: "accept",
            iconColor: Qt.hsla(0.45, 0.9, 0.3, 1),
            clientFunction: "joinRoom",
            clientArgs: [chatPage.roomId],
        },
        {
            text: "Decline",
            iconName: "decline",
            iconColor: Qt.hsla(0.95, 0.9, 0.35, 1),
            clientFunction: "leaveRoom",
            clientArgs: [chatPage.roomId],
        }
    ]
}
