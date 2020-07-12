// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/ButtonLayout"

HFlickableColumnPage {
    id: page
    enabled: account && account.presence !== "offline"


    property string userId
    readonly property QtObject account: ModelStore.get("accounts").find(userId)


    function takeFocus() {
        userField.item.forceActiveFocus()
    }

    function startChat() {
        applyButton.loading = true
        errorMessage.text   = ""

        const args = [userField.item.text.trim(), encryptCheckBox.checked]

        py.callClientCoro(userId, "new_direct_chat", args, roomId => {
            applyButton.loading = false
            errorMessage.text   = ""
            pageLoader.showRoom(userId, roomId)
            mainPane.roomList.startCorrectItemSearch()

        }, (type, args) => {
            applyButton.loading = false

            let txt = qsTr("Unknown error - %1: %2").arg(type).arg(args)

            if (type === "InvalidUserInContext")
                txt = qsTr("Can't start chatting with yourself")

            if (type === "InvalidUserId")
                txt = qsTr("Invalid user ID, expected format is " +
                           "@username:homeserver")

            if (type === "MatrixNotFound")
                txt = qsTr("User not found, please verify the entered ID")

            if (type === "MatrixBadGateway")
                txt = qsTr(
                    "Could not contact this user's server, " +
                    "please verify the entered ID"
                )

            errorMessage.text = txt
        })
    }

    function cancel() {
        userField.item.reset()
        errorMessage.text = ""

        pageLoader.showPrevious()
    }


    footer: ButtonLayout {
        ApplyButton {
            id: applyButton
            text: qsTr("Start chat")
            icon.name: "start-direct-chat"
            enabled: Boolean(userField.item.text.trim())
            onClicked: startChat()
        }

        CancelButton {
            onClicked: {
                userField.item.text = ""
                errorMessage.text   = ""
                pageLoader.showPrevious()
            }
        }
    }

    onKeyboardAccept: startChat()
    onKeyboardCancel: cancel()


    CurrentUserAvatar {
        userId: page.userId
        account: page.account
    }

    HLabeledItem {
        id: userField
        label.text: qsTr("Peer user ID:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
            placeholderText: qsTr("@example:matrix.org")
            error: Boolean(errorMessage.text)
        }
    }

    EncryptCheckBox {
        id: encryptCheckBox

        Layout.fillWidth: true
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
