// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

BoxPopup {
    id: popup
    summary.text: qsTr("Leave <i>%1</i> and lose the history?").arg(roomName)
    summary.textFormat: Text.StyledText
    details.text: qsTr(
        "You will not be able to see the messages you received in " +
        "this room anymore.\n\n" +

        "If all members forget the room, it will be removed from the servers."
    )

    okText: qsTr("Forget")
    box.focusButton: "ok"

    onOk: py.callClientCoro(userId, "room_forget", [roomId], () => {
        if (window.uiState.page === "Pages/Chat/Chat.qml" &&
            window.uiState.pageProperties.userId === userId &&
            window.uiState.pageProperties.roomId === roomId)
        {
            pageLoader.showPage("Default")
            Qt.callLater(popup.destroy)
        }
    })

    onCancel: canDestroy = true
    onClosed: if (canDestroy) Qt.callLater(popup.destroy)


    property string userId: ""
    property string roomId: ""
    property string roomName: ""

    property bool canDestroy: false
}
