// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../Base"

HBox {
    color: theme.chat.roomPane.roomSettings.background

    buttonModel: [
        {
            name: "apply",
            text: qsTr("Save"),
            iconName: "apply",
            // enabled: anyChange, TODO
            enabled: false,
            loading: saveFuture !== null,
            disableWhileLoading: false,
        },
        {
            name: "cancel",
            text: qsTr("Cancel"),
            iconName: "cancel",
            enabled: anyChange || saveFuture !== null,
        },
    ]

    buttonCallbacks: ({
        apply: button => {
            if (saveFuture) saveFuture.cancel()
            // TODO
        },

        cancel: button => {
            if (saveFuture) {
                saveFuture.cancel()
                saveFuture = null
            }

            nameField.item.reset()
            topicArea.item.reset()
            encryptCheckBox.reset()
            requireInviteCheckbox.reset()
            forbidGuestsCheckBox.reset()
        },
    })


    property var saveFuture: null

    readonly property bool anyChange:
        nameField.item.changed || topicArea.item.changed ||
        encryptCheckBox.changed || requireInviteCheckbox.changed ||
        forbidGuestsCheckBox.changed

    readonly property Item keybindFocusItem: nameField.item


    HRoomAvatar {
        id: avatar
        roomId: chat.roomId
        displayName: chat.roomInfo.display_name
        mxc: chat.roomInfo.avatar_url
        // enabled: chat.roomInfo.can_set_avatar  # put this in "change avatar"

        Layout.fillWidth: true
        Layout.preferredHeight: width
        Layout.maximumWidth: 256 * theme.uiScale
        Layout.alignment: Qt.AlignCenter
    }

    HLabeledItem {
        id: nameField
        label.text: qsTr("Name:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
            maximumLength: 255
            defaultText: chat.roomInfo.given_name
            enabled: chat.roomInfo.can_set_name
            Component.onCompleted: forceActiveFocus()
        }
    }

    HLabeledItem {
        id: topicArea
        label.text: qsTr("Topic:")

        Layout.fillWidth: true

        HTextArea {
            width: parent.width
            placeholderText: qsTr("This room is about...")
            defaultText: chat.roomInfo.plain_topic
            enabled: chat.roomInfo.can_set_topic
        }
    }

    HCheckBox {
        id: encryptCheckBox
        text: qsTr("Encrypt messages")
        subtitle.text:
            qsTr("Only you and those you trust will be able to read the " +
                 "conversation") +
            `<br><font color="${theme.colors.warningText}">` +
            (
                chat.roomInfo.encrypted ?
                qsTr("Cannot be disabled") :
                qsTr("Cannot be disabled later!")
            ) +
            "</font>"
        subtitle.textFormat: Text.StyledText
        defaultChecked: chat.roomInfo.encrypted
        enabled: chat.roomInfo.can_set_encryption && ! chat.roomInfo.encrypted

        Layout.fillWidth: true
    }

    HCheckBox {
        id: requireInviteCheckbox
        text: qsTr("Require being invited")
        subtitle.text: qsTr("Users will need an invite to join the room")
        defaultChecked: chat.roomInfo.invite_required
        enabled: chat.roomInfo.can_set_join_rules

        Layout.fillWidth: true
    }

    HCheckBox {
        id: forbidGuestsCheckBox
        text: qsTr("Forbid guests")
        subtitle.text: qsTr("Users without an account won't be able to join")
        defaultChecked: ! chat.roomInfo.guests_allowed
        enabled: chat.roomInfo.can_set_guest_access

        Layout.fillWidth: true
    }

    // HCheckBox {  TODO
        // text: qsTr("Make this room visible in the public room directory")
        // checked: chat.roomInfo.published_in_directory

        // Layout.fillWidth: true
    // }

    HSpacer {}
}
