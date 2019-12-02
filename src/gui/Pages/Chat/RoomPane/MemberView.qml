// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../.."
import "../../../Base"

HColumnLayout {
    HListView {
        id: memberList
        clip: true

        model: ModelStore.get(chat.userId, chat.roomId, "members")
        // model: HSortFilterProxy {
        //     model: ModelStore.get(chat.userId, chat.roomId, "members")

        //     comparator: (a, b) =>
        //         // Sort by power level, then by display name or user ID (no @)
        //         [
        //             a.invited,
        //             b.power_level,
        //             (a.display_name || a.id.substring(1)).toLocaleLowerCase(),
        //         ] < [
        //             b.invited,
        //             a.power_level,
        //             (b.display_name || b.id.substring(1)).toLocaleLowerCase(),
        //         ]

        //         filter: (item, index) => utils.filterMatchesAny(
        //             filterField.text, item.display_name, item.id,
        //         )
        // }

        delegate: MemberDelegate {
            width: memberList.width
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    HRowLayout {
        Layout.minimumHeight: theme.baseElementsHeight
        Layout.maximumHeight: Layout.minimumHeight

        HTextField {
            id: filterField
            saveName: "memberFilterField"
            saveId: chat.roomId

            placeholderText: qsTr("Filter members")
            backgroundColor: theme.chat.roomPane.filterMembers.background
            bordered: false
            opacity: width >= 16 * theme.uiScale ? 1 : 0

            onTextChanged: memberList.model.reFilter()

            Layout.fillWidth: true
            Layout.fillHeight: true

            Behavior on opacity { HNumberAnimation {} }
        }

        HButton {
            id: inviteButton
            icon.name: "room-send-invite"
            backgroundColor: theme.chat.roomPane.inviteButton.background
            enabled: chat.roomInfo.can_invite

            toolTip.text:
                enabled ?
                qsTr("Invite members to this room") :
                qsTr("No permission to invite members to this room")

            topPadding: 0 // XXX
            bottomPadding: 0

            onClicked: utils.makePopup(
                "Popups/InviteToRoomPopup.qml",
                chat,
                {
                    userId: chat.userId,
                    roomId: chat.roomId,
                    roomName: chat.roomInfo.display_name,
                    invitingAllowed: Qt.binding(() => inviteButton.enabled),
                },
            )

            // onEnabledChanged: if (openedPopup && ! enabled)

            Layout.fillHeight: true
        }
    }
}
