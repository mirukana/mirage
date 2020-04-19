// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import Clipboard 0.1
import "../../../Base"
import "../../../Base/HTile"

HTileDelegate {
    id: member
    backgroundColor: theme.chat.roomPane.listView.member.background
    contentOpacity:
        model.invited ? theme.chat.roomPane.listView.member.invitedOpacity : 1

    contentItem: ContentRow {
        tile: member

        HUserAvatar {
            id: avatar
            userId: model.id
            displayName: model.display_name
            mxc: model.avatar_url
            powerLevel: model.power_level
            shiftMembershipIconPosition: ! roomPane.collapsed
            invited: model.invited
            compact: member.compact
        }

        HColumnLayout {
            TitleLabel {
                text: model.display_name || model.id
                color:
                    member.hovered ?
                    utils.nameColor(
                        model.display_name || model.id.substring(1)
                    ) :
                    theme.chat.roomPane.listView.member.name

                Behavior on color { HColorAnimation {} }
            }

            SubtitleLabel {
                tile: member
                text: model.display_name ? model.id : ""
                color: theme.chat.roomPane.listView.member.subtitle
            }
        }
    }

    contextMenu: HMenu {
        HMenuItem {
            icon.name: "copy-user-id"
            text: qsTr("Copy user ID")
            onTriggered: Clipboard.text = model.id
        }

        HMenuItemPopupSpawner {
            icon.name: "room-kick"
            icon.color: theme.colors.negativeBackground
            text: model.invited ? qsTr("Disinvite") : qsTr("Kick")
            enabled: chat.roomInfo.can_kick

            popup: "Popups/KickPopup.qml"
            popupParent: chat
            properties: ({
                userId: chat.userId,
                roomId: chat.roomId,
                targetUserId: model.id,
                targetDisplayName: model.display_name,
                targetIsInvited: model.invited,
            })
        }
    }


    Behavior on contentOpacity { HNumberAnimation {} }
    Behavior on spacing { HNumberAnimation {} }

    Binding on spacing {
        value: (roomPane.minimumSize - avatar.width) / 2
        when: avatar && roomPane.width < avatar.width + theme.spacing * 2
    }
}
