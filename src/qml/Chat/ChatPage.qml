import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils
import "Banners"
import "Timeline"
import "FileTransfer"

HPage {
    id: chatPage
    leftPadding: 0
    rightPadding: 0

    // The target will be our EventList, not the page itself
    becomeKeyboardFlickableTarget: false


    readonly property alias composer: composer


    RoomHeader {
        Layout.fillWidth: true
    }

    LoadingRoomProgressBar {
        Layout.fillWidth: true
    }

    EventList {
        id: eventList

        // Avoid a certain binding loop
        Layout.minimumWidth: theme.minimumSupportedWidth
        Layout.fillWidth: true
        Layout.fillHeight: true
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
        visible: ! chat.roomInfo.left &&
                 ! chat.roomInfo.inviter_id
    }

}
