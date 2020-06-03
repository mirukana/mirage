// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HBox {
    id: addChatBox
    clickButtonOnEnter: "apply"

    onFocusChanged: nameField.item.forceActiveFocus()

    buttonModel: [
        { name: "apply", text: qsTr("Create"), iconName: "room-create" },
        { name: "cancel", text: qsTr("Cancel"), iconName: "cancel" },
    ]

    buttonCallbacks: ({
        apply: button => {
            button.loading    = true
            errorMessage.text = ""

            const args = [
                nameField.item.text,
                topicField.item.text,
                publicCheckBox.checked,
                encryptCheckBox.checked,
                ! blockOtherServersCheckBox.checked,
            ]

            py.callClientCoro(userId, "new_group_chat", args, roomId => {
                button.loading = false
                pageLoader.showRoom(userId, roomId)

            }, (type, args) => {
                button.loading = false
                errorMessage.text =
                    qsTr("Unknown error - %1: %2").arg(type).arg(args)
            })
        },

        cancel: button => {
            nameField.item.text               = ""
            topicField.item.text              = ""
            publicCheckBox.checked            = false
            encryptCheckBox.checked           = false
            blockOtherServersCheckBox.checked = false

            pageLoader.showPrevious()
        }
    })


    readonly property string userId: addChatPage.userId


    HRoomAvatar {
        id: avatar
        roomId: ""
        displayName: nameField.item.text

        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: 128
        Layout.preferredHeight: Layout.preferredWidth

        CurrentUserAvatar {
            anchors.fill: parent
            z: 10
            opacity: nameField.item.text ? 0 : 1
            visible: opacity > 0

            Behavior on opacity { HNumberAnimation {} }
        }
    }

    HLabeledItem {
        id: nameField
        label.text: qsTr("Name:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
            maximumLength: 255
        }
    }

    HLabeledItem {
        id: topicField
        label.text: qsTr("Topic:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
            placeholderText: qsTr("This room is about...")
        }
    }

    HCheckBox {
        id: publicCheckBox
        text: qsTr("Make this room public")
        subtitle.text:
            qsTr("Anyone will be able to join with no invite required")

        Layout.fillWidth: true
    }

    EncryptCheckBox {
        id: encryptCheckBox

        Layout.fillWidth: true
    }

    HCheckBox {
        id: blockOtherServersCheckBox
        text: qsTr("Reject users from other matrix servers")
        subtitle.text: qsTr("Cannot be changed later!")
        subtitle.color: theme.colors.warningText

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
