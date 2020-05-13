// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import ".."
import "../Base"
import "../Base/HTile"

HTileDelegate {
    id: room
    backgroundColor: theme.accountView.roomList.room.background
    leftPadding: theme.spacing * 2
    rightPadding: theme.spacing
    opacity:
        model.left ? theme.accountView.roomList.room.leftRoomOpacity : 1

    contentItem: ContentRow {
        tile: room

        HRoomAvatar {
            id: avatar
            roomId: model.id
            displayName: model.display_name
            mxc: model.avatar_url
            compact: room.compact
            radius: theme.accountView.roomList.room.avatarRadius

            Behavior on radius { HNumberAnimation {} }
        }

        HColumnLayout {
            HRowLayout {
                spacing: room.spacing

                TitleLabel {
                    text: model.display_name || qsTr("Empty room")
                    color: theme.accountView.roomList.room.name
                }

                MessageIndicator {
                    indicatorTheme:
                        theme.accountView.roomList.room.unreadIndicator
                    unreads: model.unreads
                    mentions: model.mentions
                }

                HIcon {
                    svgName: "invite-received"
                    colorize: theme.colors.alertBackground
                    small: room.compact
                    visible: invited

                    Layout.maximumWidth: invited ? implicitWidth : 0

                    Behavior on Layout.maximumWidth { HNumberAnimation {} }
                }

                TitleRightInfoLabel {
                    tile: room
                    color: theme.accountView.roomList.room.lastEventDate
                    text: {
                        model.last_event_date < new Date(1) ?
                        "" :

                        // e.g. "03:24"
                        utils.dateIsToday(model.last_event_date) ?
                        utils.formatTime(model.last_event_date, false) :

                        // e.g. "5 Dec"
                        model.last_event_date.getFullYear() ===
                        new Date().getFullYear() ?
                        Qt.formatDate(model.last_event_date, "d MMM") :

                        // e.g. "Jan 2020"
                        Qt.formatDate(model.last_event_date, "MMM yyyy")
                    }
                }
            }

            SubtitleLabel {
                tile: room
                color: theme.accountView.roomList.room.subtitle
                textFormat: Text.StyledText
                font.italic:
                    lastEvent && lastEvent.event_type === "RoomMessageEmote"

                text: {
                    if (! lastEvent) return ""

                    const ev_type      = lastEvent.event_type
                    const isEmote      = ev_type === "RoomMessageEmote"
                    const isMsg        = ev_type.startsWith("RoomMessage")
                    const isUnknownMsg = ev_type === "RoomMessageUnknown"
                    const isCryptMedia = ev_type.startsWith("RoomEncrypted")

                    // If it's a general event
                    if (isEmote || isUnknownMsg || (! isMsg && ! isCryptMedia))
                        return utils.processedEventText(lastEvent)

                    const text = utils.coloredNameHtml(
                        lastEvent.sender_name, lastEvent.sender_id
                    ) + ": " + lastEvent.inline_content

                    const subColor =
                        theme.accountView.roomList.room.subtitleQuote

                    return text.replace(
                        /< *span +class=['"]?quote['"]? *>(.+?)<\/ *span *>/g,
                        `<font color="${subColor}">` +
                        `$1</font>`,
                    )
                }
            }
        }
    }

    contextMenu: HMenu {
        HMenuItemPopupSpawner {
            visible: joined
            enabled: model.can_invite
            icon.name: "room-send-invite"
            text: qsTr("Invite members")

            popup: "Popups/InviteToRoomPopup.qml"
            properties: ({
                userId: model.for_account,
                roomId: model.id,
                roomName: model.display_name,
                invitingAllowed: Qt.binding(() => model.can_invite)
            })
        }

        HMenuItem {
            icon.name: "copy-room-id"
            text: qsTr("Copy room ID")
            onTriggered: Clipboard.text = model.id
        }

        HMenuItem {
            visible: invited
            icon.name: "invite-accept"
            icon.color: theme.colors.positiveBackground
            text: qsTr("Accept %1's invite").arg(utils.coloredNameHtml(
                model.inviter_name, model.inviter_id
            ))
            label.textFormat: Text.StyledText

            onTriggered: py.callClientCoro(
                model.for_account, "join", [model.id]
            )
        }

        HMenuItemPopupSpawner {
            visible: invited || joined
            icon.name: invited ? "invite-decline" : "room-leave"
            icon.color: theme.colors.negativeBackground
            text: invited ? qsTr("Decline invite") : qsTr("Leave")

            popup: "Popups/LeaveRoomPopup.qml"
            properties: ({
                userId: model.for_account,
                roomId: model.id,
                roomName: model.display_name,
            })
        }

        HMenuItemPopupSpawner {
            icon.name: "room-forget"
            icon.color: theme.colors.negativeBackground
            text: qsTr("Forget")

            popup: "Popups/ForgetRoomPopup.qml"
            autoDestruct: false
            properties: ({
                userId: model.for_account,
                roomId: model.id,
                roomName: model.display_name,
            })
        }
    }


    readonly property bool joined: ! invited && ! parted
    readonly property bool invited: model.inviter_id && ! parted
    readonly property bool parted: model.left

    readonly property ListModel eventModel:
        ModelStore.get(model.for_account, model.id, "events")

    readonly property QtObject lastEvent:
        eventModel.count > 0 ? eventModel.get(0) : null


    Behavior on opacity { HNumberAnimation {} }
}
