// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../../Base"
import "../../../Base/Buttons"

HFlickableColumnPage {
    id: settingsView

    property string saveFutureId: ""

    readonly property bool anyChange:
        nameField.item.changed || topicArea.item.area.changed ||
        encryptCheckBox.changed || requireInviteCheckbox.changed ||
        forbidGuestsCheckBox.changed

    readonly property Item keybindFocusItem:
        nameField.item.enabled ? nameField.item : copyIdButton

    function save() {
        if (saveFutureId) py.cancelCoro(saveFutureId)

        const args = [
            chat.roomId,
            nameField.item.changed ? nameField.item.text : undefined,
            topicArea.item.area.changed ? topicArea.item.area.text : undefined,
            encryptCheckBox.changed ? true : undefined,

            requireInviteCheckbox.changed ?
            requireInviteCheckbox.checked : undefined,

            forbidGuestsCheckBox.changed ?
            forbidGuestsCheckBox.checked : undefined,
        ]

        function onDone() { saveFutureId = "" }

        saveFutureId = py.callClientCoro(
            chat.userId, "room_set", args, onDone, onDone,
        )
    }

    function cancel() {
        if (saveFutureId) {
            py.cancelCoro(saveFutureId)
            saveFutureId = ""
        }

        nameField.item.reset()
        topicArea.item.area.reset()
        encryptCheckBox.reset()
        requireInviteCheckbox.reset()
        forbidGuestsCheckBox.reset()
    }

    enableFlickShortcuts: ! chat.composerHasFocus

    background: Rectangle {
        color: theme.chat.roomPane.roomSettings.background
    }

    footer: AutoDirectionLayout {
        ApplyButton {
            id: applyButton
            enabled: anyChange
            loading: saveFutureId !== ""
            disableWhileLoading: false
            onClicked: save()

        }

        CancelButton {
            enabled: anyChange || saveFutureId !== ""
            onClicked: cancel()
        }
    }

    onKeyboardAccept: if (applyButton.enabled) applyButton.clicked()
    onKeyboardCancel: cancel()

    Connections {
        target: pageLoader
        onAboutToRecycle: cancel()
    }

    HRoomAvatar {
        id: avatar
        clientUserId: chat.userId
        roomId: chat.roomId
        displayName: nameField.item.text || chat.roomInfo.display_name
        mxc: chat.roomInfo.avatar_url
        // enabled: chat.roomInfo.can_set_avatar  # put this in "change avatar"

        Layout.fillWidth: true
        Layout.preferredHeight: width
        Layout.maximumWidth: 256 * theme.uiScale
        Layout.alignment: Qt.AlignCenter
    }

    HLabeledItem {
        label.text: qsTr("Room ID:")
        Layout.fillWidth: true

        HRowLayout {
            width: parent.width

            HTextArea {
                id: idAreaItem
                wrapMode: HLabel.WrapAnywhere
                readOnly: true
                radius: 0
                text: chat.roomId

                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            FieldCopyButton {
                id: copyIdButton
                textControl: idAreaItem
            }
        }
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
        }
    }

    HLabeledItem {
        id: topicArea
        elementsOpacity: topicAreaIn.opacity
        label.text: qsTr("Topic:")

        Layout.fillWidth: true

        HScrollView {
            readonly property alias area: topicAreaIn

            clip: true
            width: parent.width
            height:
                Math.min(topicAreaIn.implicitHeight, settingsView.height / 2)

            HTextArea {
                id: topicAreaIn
                placeholderText: qsTr("This room is about...")
                defaultText: chat.roomInfo.plain_topic
                enabled: chat.roomInfo.can_set_topic

                focusItemOnTab:
                    encryptCheckBox.checked ?
                    requireInviteCheckbox :
                    encryptCheckBox
            }
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
