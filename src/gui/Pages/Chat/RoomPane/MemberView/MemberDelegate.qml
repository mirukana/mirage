// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import Clipboard 0.1
import "../../../.."
import "../../../../Base"
import "../../../../Base/HTile"
import "../../../../Popups"

HTile {
    id: member

    property bool colorName: hovered
    property string getPresenceFutureId: ""

    backgroundColor: theme.chat.roomPane.listView.member.background
    contentOpacity:
        model.invited || model.ignored ?
        theme.chat.roomPane.listView.member.invitedOpacity :
        1

    contentItem: ContentRow {
        tile: member

        HUserAvatar {
            id: avatar
            clientUserId: chat.userId
            userId: model.id
            displayName: model.ignored ? "" : model.display_name
            mxc: model.ignored ? "" : model.avatar_url
            powerLevel: model.power_level
            invited: model.invited
            compact: member.compact
            presence: model.ignored ? "offline" : model.presence
            shiftMembershipIconPositionBy:
                roomPane.width >= width + 8 * 3 ? -8 : -4
        }

        HColumnLayout {
            HRowLayout {
                spacing: theme.spacing

                TitleLabel {
                    text:
                        model.ignored ?
                        model.id :
                        (model.display_name || model.id)

                    color:
                        member.colorName ?
                        utils.nameColor(
                            model.ignored ?
                            model.id :
                            (model.display_name || model.id.substring(1))
                        ) :
                        theme.chat.roomPane.listView.member.name

                    Behavior on color { HColorAnimation {} }
                }

                TitleRightInfoLabel {
                    id: lastActiveAt
                    tile: member
                    visible: ! model.ignored && presenceTimer.running
                    hideUnderWidth: 130
                }
            }

            SubtitleLabel {
                tile: member
                textFormat: SubtitleLabel.PlainText
                color: theme.chat.roomPane.listView.member.subtitle
                text:
                    model.ignored ?
                    qsTr("Ignored") :
                    (model.status_msg.trim() || model.id)
            }

            HoverHandler { id: nameHover }

            HToolTip {
                visible: nameHover.hovered
                text:
                    model.id +
                    (
                        ! model.ignored && model.status_msg.trim() ?
                        " - " + model.status_msg.trim() :
                        ""
                    )
            }

            Timer {
                id: presenceTimer
                repeat: true
                running:
                    ! model.ignored &&
                    ! model.currently_active &&
                    model.last_active_at > new Date(1)

                interval:
                    new Date() - model.last_active_at < 60000 ? 10000 : 60000

                triggeredOnStart: true
                onTriggered: lastActiveAt.text = Qt.binding(() =>
                    utils.formatRelativeTime(new Date() - model.last_active_at)
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
            icon.name: model.ignored ? "stop-ignore-user" : "ignore-user"
            icon.color:
                model.ignored ?
                theme.colors.positiveBackground :
                theme.colors.negativeBackground

            text: model.ignored ? qsTr("Stop ignoring") : qsTr("Ignore")

            popup: "Popups/IgnoreUserPopup.qml"
            properties: ({
                userId: chat.userId,
                targetUserId: model.id,
                targetDisplayName: model.display_name,
                ignore: ! model.ignored
            })
        }

        HMenuItemPopupSpawner {
            property bool permissionToKick: false

            icon.name: "room-kick"
            icon.color: theme.colors.negativeBackground
            text: model.invited ? qsTr("Disinvite") : qsTr("Kick")
            enabled: chat.userInfo.presence !== "offline" && permissionToKick

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
                can => { permissionToKick = can },
            )
        }

        HMenuItemPopupSpawner {
            property bool permissionToBan: false

            icon.name: "room-ban"
            icon.color: theme.colors.negativeBackground
            text: qsTr("Ban")
            enabled: chat.userInfo.presence !== "offline" && permissionToBan

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
                can => { permissionToBan = can },
            )
        }
    }

    Component.onCompleted:
        if (model.presence === "offline" && model.last_active_at < new Date(1))
            getPresenceFutureId = py.callClientCoro(
                chat.userId,
                "get_offline_presence",
                [model.id],
                () => { getPresenceFutureId = "" }
            )

    Component.onDestruction:
        if (getPresenceFutureId) py.cancelCoro(getPresenceFutureId)

    Behavior on contentOpacity { HNumberAnimation {} }
    Behavior on spacing { HNumberAnimation {} }

    Binding on spacing {
        value: (roomPane.minimumSize - avatar.width) / 2
        when: avatar && roomPane.width < avatar.width + theme.spacing * 2
    }

    DelegateTransitionFixer {}
}
