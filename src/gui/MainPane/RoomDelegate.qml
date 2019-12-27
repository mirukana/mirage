// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import "../Base"

HTileDelegate {
    id: roomDelegate
    spacing: theme.spacing
    backgroundColor: theme.mainPane.room.background
    opacity: model.data.left ? theme.mainPane.room.leftRoomOpacity : 1

    shouldBeCurrent:
        window.uiState.page === "Pages/Chat/Chat.qml" &&
        window.uiState.pageProperties.userId === model.user_id &&
        window.uiState.pageProperties.roomId === model.data.room_id

    setCurrentTimer.running:
        ! mainPaneList.activateLimiter.running && ! mainPane.hasFocus


    Behavior on opacity { HNumberAnimation {} }


    readonly property bool joined: ! invited && ! parted
    readonly property bool invited: model.data.inviter_id && ! parted
    readonly property bool parted: model.data.left
    readonly property var lastEvent: model.data.last_event


    onActivated: pageLoader.showRoom(model.user_id, model.data.room_id)


    image: HRoomAvatar {
        displayName: model.data.display_name
        mxc: model.data.avatar_url
    }

    title.color: theme.mainPane.room.name
    title.text: model.data.display_name || qsTr("Empty room")

    additionalInfo.children: HIcon {
        svgName: "invite-received"
        colorize: theme.colors.alertBackground

        visible: invited
        Layout.maximumWidth: invited ? implicitWidth : 0

        Behavior on Layout.maximumWidth { HNumberAnimation {} }
    }

    rightInfo.color: theme.mainPane.room.lastEventDate
    rightInfo.text: {
        ! lastEvent || ! lastEvent.date ?
        "" :

        utils.dateIsToday(lastEvent.date) ?
        utils.formatTime(lastEvent.date, false) :  // no seconds

        lastEvent.date.getFullYear() === new Date().getFullYear() ?
        Qt.formatDate(lastEvent.date, "d MMM") : // e.g. "5 Dec"

        lastEvent.date.getFullYear()
    }

    subtitle.color: theme.mainPane.room.subtitle
    subtitle.font.italic:
        Boolean(lastEvent && lastEvent.event_type === "RoomMessageEmote")
    subtitle.textFormat: Text.StyledText
    subtitle.text: {
        if (! lastEvent) return ""

        let isEmote      = lastEvent.event_type === "RoomMessageEmote"
        let isMsg        = lastEvent.event_type.startsWith("RoomMessage")
        let isUnknownMsg = lastEvent.event_type === "RoomMessageUnknown"
        let isCryptMedia = lastEvent.event_type.startsWith("RoomEncrypted")

        // If it's a general event
        if (isEmote || isUnknownMsg || (! isMsg && ! isCryptMedia)) {
            return utils.processedEventText(lastEvent)
        }

        let text = utils.coloredNameHtml(
            lastEvent.sender_name, lastEvent.sender_id
        ) + ": " + lastEvent.inline_content

        return text.replace(
            /< *span +class=['"]?quote['"]? *>(.+?)<\/ *span *>/g,
            `<font color="${theme.mainPane.room.subtitleQuote}">$1</font>`,
        )
    }

    contextMenu: HMenu {
        HMenuItemPopupSpawner {
            visible: joined
            enabled: model.data.can_invite
            icon.name: "room-send-invite"
            text: qsTr("Invite members")

            popup: "Popups/InviteToRoomPopup.qml"
            properties: ({
                userId: model.user_id,
                roomId: model.data.room_id,
                roomName: model.data.display_name,
                invitingAllowed: Qt.binding(() => model.data.can_invite)
            })
        }

        HMenuItem {
            icon.name: "copy-room-id"
            text: qsTr("Copy room ID")
            onTriggered: Clipboard.text = model.data.room_id
        }

        HMenuItem {
            visible: invited
            icon.name: "invite-accept"
            icon.color: theme.colors.positiveBackground
            text: qsTr("Accept %1's invite").arg(utils.coloredNameHtml(
                model.data.inviter_name, model.data.inviter_id
            ))
            label.textFormat: Text.StyledText

            onTriggered: py.callClientCoro(
                model.user_id, "join", [model.data.room_id]
            )
        }

        HMenuItemPopupSpawner {
            visible: invited || joined
            icon.name: invited ? "invite-decline" : "room-leave"
            icon.color: theme.colors.negativeBackground
            text: invited ? qsTr("Decline invite") : qsTr("Leave")

            popup: "Popups/LeaveRoomPopup.qml"
            properties: ({
                userId: model.user_id,
                roomId: model.data.room_id,
                roomName: model.data.display_name,
            })
        }

        HMenuItemPopupSpawner {
            icon.name: "room-forget"
            icon.color: theme.colors.negativeBackground
            text: qsTr("Forget")

            popup: "Popups/ForgetRoomPopup.qml"
            autoDestruct: false
            properties: ({
                userId: model.user_id,
                roomId: model.data.room_id,
                roomName: model.data.display_name,
            })
        }
    }
}
