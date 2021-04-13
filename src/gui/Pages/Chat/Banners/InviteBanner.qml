// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../../Base"

Banner {
    id: root

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
            window.makePopup(
                "Popups/LeaveRoomPopup.qml",
                {
                    userId: chat.userId,
                    roomId: chat.roomId,
                    roomName: chat.roomInfo.display_name,
                    inviterId: root.inviterId,
                    left: chat.roomInfo.left,
                    leftCallback: () => { button.loading = true },
                },
            )
        }
    })
}
