import QtQuick 2.7
import "../../Base"

Banner {
    property var inviter: null

    color: HStyle.chat.inviteBanner.background

    // TODO: get disp name from models.users, inviter = userid  now
    avatar.name: inviter ? inviter.displayname : ""
    //avatar.imageUrl: inviter ? inviter.avatar_url : ""

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
            Backend.clients.get(chatPage.userId).joinRoom(chatPage.roomId)
        },

        "decline": function(button) {
            button.loading = true
            Backend.clients.get(chatPage.userId).leaveRoom(chatPage.roomId)
        }
    }
}
