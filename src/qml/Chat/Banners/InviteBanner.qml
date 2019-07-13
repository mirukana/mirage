// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

Banner {
    property string inviterId: ""

    readonly property var inviterInfo:
        inviterId ? users.find(inviterId) : null

    color: theme.chat.inviteBanner.background

    avatar.userId: inviterId

    labelText: qsTr("%1 invited you to join the room.").arg(
        inviterId && inviterInfo ?
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
                chatPage.userId, "join", [chatPage.roomId], function() {
                    button.loading = false
            })
        },

        "decline": function(button) {
            button.loading = true
            py.callClientCoro(
                chatPage.userId, "room_leave", [chatPage.roomId], function() {
                    button.loading = false
            })
        }
    }
}
