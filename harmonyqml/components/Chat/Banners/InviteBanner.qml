import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../../Base" as Base

Banner {
    property var inviter: null

    color: Base.HStyle.chat.inviteBanner.background

    avatarName: inviter ? inviter.displayname : ""
    //avatarSource: inviter ? inviter.avatar_url : ""

    labelText:
        (inviter ?
         ("<b>" + inviter.displayname + "</b>") : qsTr("Someone")) +
        " " + qsTr("invited you to join the room.")

    buttonModel: [
        {
            name: "accept",
            text: qsTr("Accept"),
            iconName: "invite_accept",
        },
        {
            name: "decline",
            text: qsTr("Decline"),
            iconName: "invite_decline",
        }
    ]

    buttonCallbacks: {
        "accept": function(button) {
            button.loading = true
            Backend.clientManager.clients[chatPage.userId].joinRoom(
                chatPage.roomId
            )
        },

        "decline": function(button) {
            button.loading = true
            Backend.clientManager.clients[chatPage.userId].leaveRoom(
                chatPage.roomId
            )
        }
    }
}
