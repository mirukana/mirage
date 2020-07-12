// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import ".."
import "../Base"
import "../Base/HTile"

HTile {
    id: room

    readonly property bool joined: ! invited && ! parted
    readonly property bool invited: model.inviter_id && ! parted
    readonly property bool parted: model.left

    readonly property ListModel eventModel:
        ModelStore.get(model.for_account, model.id, "events")

    // FIXME: binding loop
    readonly property QtObject accountModel:
        ModelStore.get("accounts").find(model.for_account)

    readonly property QtObject lastEvent:
        eventModel.count > 0 ? eventModel.get(0) : null


    backgroundColor: theme.mainPane.listView.room.background
    leftPadding: theme.spacing * 2
    rightPadding: theme.spacing

    contentItem: ContentRow {
        tile: room
        opacity:
            accountModel.presence === "offline" ?
            theme.mainPane.listView.offlineOpacity :

            model.left ?
            theme.mainPane.listView.room.leftRoomOpacity :
            1

        Behavior on opacity { HNumberAnimation {} }

        HRoomAvatar {
            id: avatar
            roomId: model.id
            displayName: model.display_name
            mxc: model.avatar_url
            compact: room.compact
            radius: theme.mainPane.listView.room.avatarRadius

            Behavior on radius { HNumberAnimation {} }
        }

        HColumnLayout {
            HRowLayout {
                spacing: room.spacing

                TitleLabel {
                    text: model.display_name || qsTr("Empty room")
                    color:
                        model.local_unreads ?
                        theme.mainPane.listView.room.unreadName :
                        theme.mainPane.listView.room.name
                }

                MessageIndicator {
                    indicatorTheme:
                        theme.mainPane.listView.room.unreadIndicator
                    unreads: model.unreads
                    highlights: model.highlights
                    localUnreads: model.local_unreads
                    localHighlights: model.local_highlights
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
                    color: theme.mainPane.listView.room.lastEventDate
                    text: utils.smartFormatDate(model.last_event_date)
                }
            }

            SubtitleLabel {
                tile: room
                color: theme.mainPane.listView.room.subtitle
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
                        theme.mainPane.listView.room.subtitleQuote

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
            enabled: model.can_invite && accountModel.presence !== "offline"
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
            enabled: accountModel.presence !== "offline"

            onTriggered: py.callClientCoro(
                model.for_account, "join", [model.id]
            )
        }

        HMenuItemPopupSpawner {
            visible: invited || joined
            icon.name: invited ? "invite-decline" : "room-leave"
            icon.color: theme.colors.negativeBackground
            text: invited ? qsTr("Decline invite") : qsTr("Leave")
            enabled: accountModel.presence !== "offline"

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
            enabled: accountModel.presence !== "offline"

            popup: "Popups/ForgetRoomPopup.qml"
            autoDestruct: false
            properties: ({
                userId: model.for_account,
                roomId: model.id,
                roomName: model.display_name,
            })
        }
    }
}
