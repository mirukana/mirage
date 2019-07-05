import QtQuick 2.7
import "../../Base"
import "../../utils.js" as Utils

Banner {
    property string inviterId: ""

    readonly property var inviterInfo:
        inviterId ? users.getUser(inviterId) : null

    color: HStyle.chat.inviteBanner.background

    avatar.name: inviterId ? inviterInfo.displayName : ""
    avatar.imageUrl: inviterId ? inviterInfo.avatarUrl : ""

    labelText: qsTr("%1 invited you to join the room.").arg(
        inviterId ?
        Utils.coloredNameHtml(inviterInfo.displayName, inviterId) :
        qsTr("Someone")
    )

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
            py.callClientCoro(
                chatPage.userId, "join", [chatPage.roomId], {},
                function() { button.loading = false }
            )
        },

        "decline": function(button) {
            button.loading = true
            py.callClientCoro(
                chatPage.userId, "room_leave", [chatPage.roomId], {},
                function() { button.loading = false }
            )
        }
    }
}
