// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../Base"

BoxPopup {
    id: popup
    // fillAvailableHeight: true
    summary.text: qsTr("Invite members to <i>%1</i>").arg(roomName)
    summary.textFormat: Text.StyledText
    okText: qsTr("Invite")
    okEnabled: invitingAllowed && Boolean(inviteArea.text.trim())

    onOpened: inviteArea.forceActiveFocus()

    onInvitingAllowedChanged:
        if (! invitingAllowed && inviteFuture) inviteFuture.cancel()

    box.buttonCallbacks: ({
        ok: button => {
            button.loading = true

            const inviteesLeft = inviteArea.text.trim().split(/\s+/).filter(
                user => ! successfulInvites.includes(user)
            )

            inviteFuture = py.callClientCoro(
                userId,
                "room_mass_invite",
                [roomId, ...inviteesLeft],

                ([successes, errors]) => {
                    if (errors.length < 1) {
                        popup.close()
                        return
                    }

                    successfulInvites = successes
                    failedInvites     = errors
                    button.loading    = false
                }
            )
        },

        cancel: button => {
            if (inviteFuture) inviteFuture.cancel()
            popup.close()
        },
    })


    property string userId
    property string roomId
    property string roomName
    property bool invitingAllowed: true

    property var inviteFuture: null
    property var successfulInvites: []
    property var failedInvites: []


    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true

        HTextArea {
            id: inviteArea
            focusItemOnTab: box.firstButton
            placeholderText:
                qsTr("User IDs (e.g. @bob:matrix.org @alice:localhost)")
        }
    }

    HLabel {
        id: errorMessage
        visible: Layout.maximumHeight > 0
        wrapMode: Text.Wrap
        color: theme.colors.errorText
        text:
            invitingAllowed ?
            allErrors :
            qsTr("You do not have permission to invite members to this room")

        Layout.maximumHeight: text ? implicitHeight : 0
        Layout.fillWidth: true

        readonly property string allErrors: {
            // TODO: handle these: real user not found
            const lines = []

            for (const [user, error] of failedInvites) {
                const type = py.getattr(
                    py.getattr(error, "__class__"), "__name__",
                )

                lines.push(
                    type === "InvalidUserId" ?
                    qsTr("%1 is not a valid user ID, expected format is " +
                         "@username:homeserver").arg(user) :

                    type === "UserFromOtherServerDisallowed" ?
                    qsTr("This room rejects users from other matrix " +
                         "servers, can't invite %1").arg(user) :

                    type === "UserNotFound" ?
                    qsTr("%1 not found, please verify the entered user ID")
                    .arg(user) :

                    type === "MatrixBadGateway" ?
                    qsTr("Server error while trying to find %1, please " +
                         "verify the entered user ID").arg(user) :

                    type === "MatrixUnsupportedRoomVersion" ?
                    qsTr("%1's server does not support this room's version")
                    .arg(user) :

                    type === "MatrixForbidden" ?
                    qsTr("%1 is banned from this room")
                    .arg(user) :

                    qsTr("Unknown error while inviting %1: %2 - %3")
                    .arg(user).arg(type).arg(py.getattr(error, "args"))
                )
            }

            return lines.join("\n\n")
        }

        Behavior on Layout.maximumHeight { HNumberAnimation {} }
    }
}
