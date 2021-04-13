// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/Buttons"

HFlickableColumnPopup {
    id: popup

    property string userId: ""
    property string roomId: ""
    property string roomName: ""
    property string inviterId: ""
    property bool left: false

    function forget() {
        py.callClientCoro(userId, "room_forget", [roomId], () => {
            if (window.uiState.page === "Pages/Chat/Chat.qml" &&
                window.uiState.pageProperties.userRoomId[0] === userId &&
                window.uiState.pageProperties.userRoomId[1] === roomId)
            {
                window.mainUI.pageLoader.showPrevious() ||
                window.mainUI.pageLoader.show("Pages/Default.qml")

                Qt.callLater(popup.destroy)
            }
        })
    }

    function leave() {
        py.callClientCoro(userId, "room_leave", [roomId])
        popup.close()
    }

    page.footer: AutoDirectionLayout {
        ApplyButton {
            id: leaveButton
            icon.name: popup.left ? "room-forget" : "room-leave"
            text:
                popup.left ? qsTr("Forget") :
                popup.inviterId ? qsTr("Decline") :
                qsTr("Leave")

            onClicked:
                forgetCheck.checked || popup.left ?
                popup.forget() :
                popup.leave()
        }

        CancelButton {
            onClicked: popup.close()
        }
    }

    onOpened: leaveButton.forceActiveFocus()

    SummaryLabel {
        readonly property string roomText:
            utils.htmlColorize(popup.roomName, theme.colors.accentText)

        textFormat: Text.StyledText
        text:
            popup.left ? qsTr("Forget the history for %1?").arg(roomText) :
            popup.inviterId ? qsTr("Decline invite to %1?").arg(roomText) :
            qsTr("Leave %1?").arg(roomText)
    }

    DetailsLabel {
        text:
            popup.left ?
            forgetCheck.subtitle.text :
            qsTr(
                "If this room is private, you will not be able to rejoin it " +
                "without a new invite."
            )
    }

    HCheckBox {
        id: forgetCheck
        visible: ! popup.left
        text: qsTr("Forget this room's history")
        subtitle.text: qsTr(
            "You will lose access to any previously received messages.\n" +
            "If all members forget a room, servers will erase it."
        )

        Layout.fillWidth: true
    }
}
