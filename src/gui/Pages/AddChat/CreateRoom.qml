// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/Buttons"

HFlickableColumnPage {
    id: page

    property string userId
    readonly property QtObject account: ModelStore.get("accounts").find(userId)

    function takeFocus() { nameField.item.forceActiveFocus() }

    function create() {
        applyButton.loading = true
        errorMessage.text   = ""

        const args = [
            nameField.item.text,
            topicArea.item.text,
            publicCheckBox.checked,
            encryptCheckBox.checked,
            ! blockOtherServersCheckBox.checked,
        ]

        py.callClientCoro(userId, "new_group_chat", args, roomId => {
            applyButton.loading = false
            pageLoader.showRoom(userId, roomId)
            mainPane.roomList.startCorrectItemSearch()

        }, (type, args) => {
            applyButton.loading = false
            errorMessage.text   =
                qsTr("Unknown error - %1: %2").arg(type).arg(args)
        })
    }

    function cancel() {
        nameField.item.reset()
        topicArea.item.reset()
        publicCheckBox.reset()
        encryptCheckBox.reset()
        blockOtherServersCheckBox.reset()
        errorMessage.text = ""

        pageLoader.showPrevious()
    }

    enabled: account && account.presence !== "offline"

    footer: AutoDirectionLayout {
        ApplyButton {
            id: applyButton
            text: qsTr("Create")
            icon.name: "room-create"
            onClicked: create()
        }

        CancelButton {
            onClicked: cancel()
        }
    }

    onKeyboardAccept: if (applyButton.enabled) applyButton.clicked()
    onKeyboardCancel: cancel()

    HRoomAvatar {
        id: avatar
        clientUserId: page.userId
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

            userId: page.userId
            account: page.account

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
        id: topicArea
        label.text: qsTr("Topic:")

        Layout.fillWidth: true

        HTextArea {
            width: parent.width
            placeholderText: qsTr("This room is about...")
            focusItemOnTab: publicCheckBox
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
        wrapMode: HLabel.Wrap
        horizontalAlignment: Text.AlignHCenter
        color: theme.colors.errorText

        visible: Layout.maximumHeight > 0
        Layout.maximumHeight: text ? implicitHeight : 0
        Behavior on Layout.maximumHeight { HNumberAnimation {} }

        Layout.fillWidth: true
    }
}
