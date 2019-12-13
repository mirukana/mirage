import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

// TODO: hide roompane until room is loaded & expand if too small

HBox {
    color: "transparent"
    Component.onCompleted: Utils.debug(this)  // XXX

    HRoomAvatar {
        id: avatar
        displayName: chat.roomInfo.display_name
        mxc: chat.roomInfo.avatar_url
        // enabled: chat.roomInfo.can_set_avatar  # put this in "change avatar"

        Layout.fillWidth: true
        Layout.preferredHeight: width
        Layout.maximumWidth: 256 * theme.uiScale
    }

    HTextField {
        id: nameField
        placeholderText: qsTr("Room name")
        maximumLength: 255
        text: chat.roomInfo.given_name
        enabled: chat.roomInfo.can_set_name

        Layout.fillWidth: true
    }

    HScrollableTextArea {
        id: topicField
        placeholderText: qsTr("Room topic")
        text: chat.roomInfo.plain_topic
        enabled: chat.roomInfo.can_set_topic

        Layout.fillWidth: true
    }

    HCheckBox {
        id: encryptCheckBox
        text: qsTr("Encrypt messages")
        subtitle.text:
            qsTr("Only you and those you trust will be able to read the " +
                 "conversation") +
            `<br><font color="${theme.colors.middleBackground}">` +
            (
                chat.roomInfo.encrypted ?
                qsTr("Cannot be disabled") :
                qsTr("Cannot be disabled later!")
            ) +
            "</font>"
        subtitle.textFormat: Text.StyledText
        checked: chat.roomInfo.encrypted
        enabled: chat.roomInfo.can_set_encryption && ! chat.roomInfo.encrypted

        Layout.fillWidth: true
    }

    HCheckBox {
        id: requireInviteCheckbox
        text: qsTr("Require being invited")
        subtitle.text: qsTr("Users will need an invite to join the room")
        checked: chat.roomInfo.invite_required
        enabled: chat.roomInfo.can_set_join_rules

        Layout.fillWidth: true
    }

    HCheckBox {
        text: qsTr("Forbid guests")
        subtitle.text: qsTr("Users without an account won't be able to join")
        checked: ! chat.roomInfo.guests_allowed
        enabled: chat.roomInfo.can_set_guest_access

        Layout.fillWidth: true
    }

    // HCheckBox {  TODO
        // text: qsTr("Make this room visible in the public room directory")
        // checked: chat.roomInfo.published_in_directory

        // Layout.fillWidth: true
    // }

}
