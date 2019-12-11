import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

BoxPopup {
    id: popup
    // fillAvailableHeight: true
    summary.text: qsTr("Invite room members")
    okText: qsTr("Invite")
    okEnabled: invitingAllowed && Boolean(inviteArea.text.trim())

    onOpened: inviteArea.area.forceActiveFocus()

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
    property bool invitingAllowed: true

    property var inviteFuture: null
    property var successfulInvites: []
    property var failedInvites: []


    HScrollableTextArea {
        id: inviteArea
        focusItemOnTab: box.firstButton
        area.placeholderText:
            qsTr("User IDs (e.g. @bob:matrix.org @alice:localhost)")

        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    HLabel {
        id: errorMessage
        visible: Layout.maximumHeight > 0
        wrapMode: Text.Wrap
        color: theme.colors.errorText
        text:
            invitingAllowed ?
            allErrors :
            qsTr("You do not have permission to invite members in this room")

        Layout.maximumHeight: text ? implicitHeight : 0
        Layout.fillWidth: true

        readonly property string allErrors: {
            // TODO: handle these: real user not found
            const lines = []

            for (let [user, error] of failedInvites) {
                const type = py.getattr(
                    py.getattr(error, "__class__"), "__name__",
                )

                lines.push(
                    type === "InvalidUserId" ?
                    qsTr("%1 is not a valid user ID, expected format is " +
                         "@username:homeserver").arg(user) :

                    type === "UserNotFound" ?
                    qsTr("%1 not found, please verify the entered user ID")
                    .arg(user) :

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
