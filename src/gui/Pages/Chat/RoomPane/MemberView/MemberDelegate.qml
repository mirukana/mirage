// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import Clipboard 0.1
import "../../../.."
import "../../../../Base"
import "../../../../Base/HTile"
import "../../../../Popups"

HTile {
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
            presence: model.presence
        }

        HColumnLayout {
            HRowLayout {
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

                TitleRightInfoLabel {
                    tile: member
                    visible: presenceTimer.running

                    Timer {
                        id: presenceTimer
                        running:
                            ! model.currently_active &&
                            model.last_active_at > new Date(1)
                        repeat: true
                        interval:
                            new Date() - model.last_active_at < 60000 ?
                            10000 :
                            60000
                        triggeredOnStart: true
                        onTriggered: parent.text = Qt.binding(() =>
                            utils.formatRelativeTime(
                                new Date() - model.last_active_at
                            )
                        )
                    }
                }
            }

            SubtitleLabel {
                tile: member
                color: theme.chat.roomPane.listView.member.subtitle
                text: utils.escapeHtml(model.status_msg.trim()) || model.id
            }

            HoverHandler { id: nameHover }

            HToolTip {
                visible: nameHover.hovered
                text:
                    model.id +
                    (
                        model.status_msg.trim() ?
                        " - " + model.status_msg.trim() :
                        ""
                    )
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
            enabled: false

            popup: "Popups/RemoveMemberPopup.qml"
            properties: ({
                userId: chat.userId,
                roomId: chat.roomId,
                targetUserId: model.id,
                targetDisplayName: model.display_name,
                operation: model.invited ? "disinvite" : "kick",
            })

            Component.onCompleted: py.callClientCoro(
                chat.userId,
                "can_kick",
                [chat.roomId, model.id],
                can => { enabled = can },
            )
        }

        HMenuItemPopupSpawner {
            icon.name: "room-ban"
            icon.color: theme.colors.negativeBackground
            text: qsTr("Ban")
            enabled: false

            popup: "Popups/RemoveMemberPopup.qml"
            properties: ({
                userId: chat.userId,
                roomId: chat.roomId,
                targetUserId: model.id,
                targetDisplayName: model.display_name,
                operation: "ban",
            })

            Component.onCompleted: py.callClientCoro(
                chat.userId,
                "can_ban",
                [chat.roomId, model.id],
                can => { enabled = can },
            )
        }
    }


    Behavior on contentOpacity { HNumberAnimation {} }
    Behavior on spacing { HNumberAnimation {} }

    Binding on spacing {
        value: (roomPane.minimumSize - avatar.width) / 2
        when: avatar && roomPane.width < avatar.width + theme.spacing * 2
    }
}
