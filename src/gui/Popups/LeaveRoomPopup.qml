// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base/ButtonLayout"

HFlickableColumnPopup {
    id: popup


    property string userId: ""
    property string roomId: ""
    property string roomName: ""
    property var leftCallback: null


    page.footer: ButtonLayout {
        ApplyButton {
            id: leaveButton
            icon.name: "room-leave"
            text: qsTr("Leave")

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
        text: qsTr("Leave <i>%1</i>?").arg(roomName)
        textFormat: Text.StyledText
    }

    DetailsLabel {
        text: qsTr(
            "If this room is private, you will not be able to rejoin it."
        )
    }
}
