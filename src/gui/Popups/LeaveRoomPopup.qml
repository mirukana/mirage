// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"
import "../Base/Buttons"

HFlickableColumnPopup {
    id: popup

    property string userId: ""
    property string roomId: ""
    property string roomName: ""
    property string inviterId: ""
    property var leftCallback: null

    page.footer: AutoDirectionLayout {
        ApplyButton {
            id: leaveButton
            icon.name: "room-leave"
            text: inviterId ? qsTr("Decline") : qsTr("Leave")

            onClicked: {
                py.callClientCoro(userId, "room_leave", [roomId], leftCallback)
                popup.close()
            }
        }

        CancelButton {
            onClicked: popup.close()
        }
    }

    onOpened: leaveButton.forceActiveFocus()

    SummaryLabel {
        readonly property string roomText:
            utils.htmlColorize(roomName, theme.colors.accentText)

        textFormat: Text.StyledText
        text:
            inviterId ?
            qsTr("Decline invite to %1?").arg(roomText) :
            qsTr("Leave %1?").arg(roomText)
    }

    DetailsLabel {
        visible: inviterId === ""
        text: qsTr(
            "If this room is private, you will not be able to rejoin it."
        )
    }
}
