// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/ButtonLayout"

HFlickableColumnPage {
    id: page
    enabled: account.presence !== "offline"


    property string userId
    readonly property QtObject account: ModelStore.get("accounts").find(userId)


    function takeFocus() {
        roomField.item.forceActiveFocus()
    }

    function join() {
        joinButton.loading    = true
        errorMessage.text = ""

        const args = [roomField.item.text.trim()]

        py.callClientCoro(userId, "room_join", args, roomId => {
            joinButton.loading = false
            errorMessage.text  = ""
            pageLoader.showRoom(userId, roomId)
            mainPane.roomList.startCorrectItemSearch()

        }, (type, args) => {
            joinButton.loading = false

            let txt = qsTr("Unknown error - %1: %2").arg(type).arg(args)

            if (type === "ValueError")
                txt = qsTr("Unrecognized alias, room ID or URL")

            if (type === "MatrixNotFound")
                txt = qsTr("Room not found")

            if (type === "MatrixForbidden")
                txt = qsTr("You do not have permission to join this room")

            errorMessage.text = txt
        })
    }

    function cancel() {
        roomField.item.reset()
        errorMessage.reset()

        pageLoader.showPrevious()
    }


    footer: ButtonLayout {
        ApplyButton {
            id: joinButton
            text: qsTr("Join")
            icon.name: "room-join"
            enabled: Boolean(roomField.item.text.trim())
            onClicked: join()
        }

        CancelButton {
            onClicked: cancel()
        }
    }

    onKeyboardAccept: join()
    onKeyboardCancel: cancel()


    CurrentUserAvatar {
        userId: page.userId
        account: page.account
    }

    HLabeledItem {
        id: roomField
        label.text: qsTr("Alias, URL or room ID:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
            placeholderText: qsTr("#example:matrix.org")
            error: Boolean(errorMessage.text)
        }
    }

    HLabel {
        id: errorMessage
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        color: theme.colors.errorText

        visible: Layout.maximumHeight > 0
        Layout.maximumHeight: text ? implicitHeight : 0
        Behavior on Layout.maximumHeight { HNumberAnimation {} }

        Layout.fillWidth: true
    }
}
