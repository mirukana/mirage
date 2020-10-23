// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "AutoCompletion"
import "Banners"
import "Composer"
import "FileTransfer"
import "Timeline"

HColumnPage {
    id: chatPage

    property string loadMembersFutureId: ""

    readonly property alias roomHeader: roomHeader
    readonly property alias eventList: eventList
    readonly property alias typingMembers: typingMembers
    readonly property alias reply: reply
    readonly property alias transfers: transfers
    readonly property alias userCompletion: userCompletion
    readonly property alias inviteBanner: inviteBanner
    readonly property alias leftBanner: leftBanner
    readonly property alias composer: composer

    readonly property DropArea uploadDropArea: UploadDropArea {
        parent: window.mainUI
        anchors.fill: parent
    }


    padding: 0
    column.spacing: 0

    Component.onDestruction:
        if (loadMembersFutureId) py.cancelCoro(loadMembersFutureId)

    Timer {
        interval: 200
        running: ! chat.roomInfo.inviter_id && ! chat.roomInfo.left
        onTriggered: loadMembersFutureId = py.callClientCoro(
            chat.userId,
            "load_all_room_members",
            [chat.roomId],
            () => { loadMembersFutureId = "" },
        )
    }

    RoomHeader {
        id: roomHeader

        Layout.fillWidth: true
    }

    EventList {
        id: eventList

        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    TypingMembersBar {
        id: typingMembers
        typingMembers: JSON.parse(chat.roomInfo.typing_members)

        Layout.fillWidth: true
    }

    ReplyBar {
        id: reply
        replyToEventId: chat.replyToEventId
        replyToUserId: chat.replyToUserId
        replyToDisplayName: chat.replyToDisplayName
        onCancel: {
            chat.replyToEventId     = ""
            chat.replyToUserId      = ""
            chat.replyToDisplayName = ""
        }

        Layout.fillWidth: true
    }

    TransferList {
        id: transfers

        Layout.fillWidth: true
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight * transferCount
        Layout.maximumHeight: chatPage.height / 6

        Behavior on Layout.preferredHeight { HNumberAnimation {} }
    }

    UserAutoCompletion {
        id: userCompletion
        textArea: composer.messageArea
        clip: true

        Layout.fillWidth: true
        Layout.maximumHeight: chatPage.height / 4
    }

    InviteBanner {
        id: inviteBanner
        visible: ! chat.roomInfo.left && inviterId
        inviterId: chat.roomInfo.inviter_id

        Layout.fillWidth: true
    }

    LeftBanner {
        id: leftBanner
        visible: chat.roomInfo.left

        Layout.fillWidth: true
    }

    Composer {
        id: composer
        userCompletion: userCompletion
        eventList: eventList.eventList
        visible: ! chat.roomInfo.left && ! chat.roomInfo.inviter_id

        Layout.fillWidth: true
        Layout.maximumHeight: parent.height / 2
    }
}
