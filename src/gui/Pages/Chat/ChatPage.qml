// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "Banners"
import "Timeline"
import "FileTransfer"

HColumnPage {
    id: chatPage
    leftPadding: 0
    rightPadding: 0

    // The target will be our EventList, not the page itself
    becomeKeyboardFlickableTarget: false


    readonly property alias composer: composer
    readonly property bool loadEventList: ! pageLoader.appearAnimation.running


    RoomHeader {
        Layout.fillWidth: true
    }

    Timer {
        id: delayEventListLoadingTimer
        interval: 150
        running: true
    }

    HLoader {
        id: eventListLoader
        sourceComponent: loadEventList ? evListComponent : placeholder
        opacity: loadEventList ? 1 : 0

        Layout.fillWidth: true
        Layout.fillHeight: true

        Behavior on opacity { HNumberAnimation {} }

        Component {
            id: placeholder
            Item {}
        }

        Component {
            id: evListComponent
            EventList {}
        }
    }

    TypingMembersBar {
        Layout.fillWidth: true
    }

    TransferList {
        Layout.fillWidth: true
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight * transferCount
        Layout.maximumHeight: chatPage.height / 6

        Behavior on Layout.preferredHeight { HNumberAnimation {} }
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
        eventList: loadEventList ? eventListLoader.item : null
        visible:
            ! chat.roomInfo.left && ! chat.roomInfo.inviter_id
    }

}
