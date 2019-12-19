// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HBox {
    id: addChatBox
    clickButtonOnEnter: "apply"

    onFocusChanged: roomField.forceActiveFocus()

    buttonModel: [
        {
            name: "apply",
            text: qsTr("Join"),
            iconName: "room-join",
            enabled: Boolean(roomField.text.trim()),
        },
        { name: "cancel", text: qsTr("Cancel"), iconName: "cancel" },
    ]

    buttonCallbacks: ({
        apply: button => {
            button.loading    = true
            errorMessage.text = ""

            let args = [roomField.text.trim()]

            py.callClientCoro(userId, "room_join", args, roomId => {
                button.loading    = false
                errorMessage.text = ""
                pageLoader.showRoom(userId, roomId)

            }, (type, args) => {
                button.loading = false

                let txt = qsTr("Unknown error - %1: %2").arg(type).arg(args)

                if (type === "ValueError")
                    txt = qsTr("Unrecognized alias, room ID or URL")

                if (type === "MatrixNotFound")
                    txt = qsTr("Room not found")

                if (type === "MatrixForbidden")
                    txt = qsTr("You do not have permission to join this room")

                errorMessage.text = txt
            })
        },

        cancel: button => {
            roomField.text    = ""
            errorMessage.text = ""
            pageLoader.showPrevious()
        }
    })


    readonly property string userId: addChatPage.userId


    CurrentUserAvatar {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: 128
        Layout.preferredHeight: Layout.preferredWidth
    }

    HTextField {
        id: roomField
        placeholderText: qsTr("Alias (e.g. #example:matrix.org), URL or ID")
        error: Boolean(errorMessage.text)

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
