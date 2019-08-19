import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

Banner {
    property string inviterId: chatPage.roomInfo.inviter
    property string inviterName: chatPage.roomInfo.inviter_name
    property string inviterAvatar: chatPage.roomInfo.inviter_avatar

    color: theme.chat.inviteBanner.background

    avatar.userId: inviterId
    avatar.displayName: inviterName
    avatar.avatarUrl: inviterAvatar

    labelText: qsTr("%1 invited you to this room.").arg(
        Utils.coloredNameHtml(inviterName, inviterId)
    )

    buttonModel: [
        {
            name: "accept",
            text: qsTr("Join"),
            iconName: "invite-accept",
        },
        {
            name: "decline",
            text: qsTr("Decline"),
            iconName: "invite-decline",
        }
    ]

    buttonCallbacks: ({
        accept: button => {
            button.loading = true
            py.callClientCoro(
                chatPage.userId, "join", [chatPage.roomId], () => {
                    button.loading = false
            })
        },

        decline: button => {
            button.loading = true
            py.callClientCoro(
                chatPage.userId, "room_leave", [chatPage.roomId], () => {
                    button.loading = false
            })
        }
    })
}
