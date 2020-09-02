// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"
import "../Base/Buttons"

HFlickableColumnPopup {
    id: popup

    property string userId: ""
    property string roomId: ""
    property string roomName: ""

    property bool canDestroy: false

    function forget() {
        py.callClientCoro(userId, "room_forget", [roomId], () => {
            if (window.uiState.page === "Pages/Chat/Chat.qml" &&
                window.uiState.pageProperties.userId === userId &&
                window.uiState.pageProperties.roomId === roomId)
            {
                window.mainUI.pageLoader.showPrevious() ||
                window.mainUI.pageLoader.showPage("Pages/Default.qml")

                Qt.callLater(popup.destroy)
            }
        })
    }


    page.footer: AutoDirectionLayout {
        ApplyButton {
            id: forgetButton
            text: qsTr("Forget")
            icon.name: "room-forget"
            onClicked: forget()
        }

        CancelButton {
            onClicked: {
                canDestroy = true
                popup.close()
            }
        }
    }

    onOpened: forgetButton.forceActiveFocus()
    onClosed: if (canDestroy) Qt.callLater(popup.destroy)

    SummaryLabel {
        text: qsTr("Leave <i>%1</i> and lose the history?").arg(roomName)
        textFormat: Text.StyledText
    }

    DetailsLabel {
        text: qsTr(
            "You will not be able to see the messages you received in " +
            "this room anymore.\n\n" +

            "If all members forget the room, it will be removed from the " +
            "servers."
        )
    }
}
