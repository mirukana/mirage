// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../../Base"

Banner {
    property string inviterId: chat.roomInfo.inviter
    property string inviterName: chat.roomInfo.inviter_name
    property string inviterAvatar: chat.roomInfo.inviter_avatar


    color: theme.chat.inviteBanner.background

    avatar.userId: inviterId
    avatar.displayName: inviterName
    avatar.mxc: inviterAvatar

    labelText: qsTr("%1 invited you to this room").arg(
        utils.coloredNameHtml(inviterName, inviterId)
    )

    buttonModel: [
        {
            name: "accept",
            text: qsTr("Join"),
            iconName: "invite-accept",
            iconColor: theme.colors.positiveBackground
        },
        {
            name: "decline",
            text: qsTr("Decline"),
            iconName: "invite-decline",
            iconColor: theme.colors.negativeBackground
        }
    ]

    buttonCallbacks: ({
        accept: button => {
            button.loading = true
            py.callClientCoro(
                chat.userId, "join", [chat.roomId], () => {
                    button.loading = false
            })
        },

        decline: button => {
            button.loading = true
            py.callClientCoro(
                chat.userId, "room_leave", [chat.roomId], () => {
                    button.loading = false
            })
        }
    })
}
