// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "RoomPane"

Item {
    id: chat

    // [userId, roomId] - Set this instead of changing the userId and roomId
    // properties one by one, else QML has time to be in an invalid state
    // between the two changes.
    property var userRoomId

    property string replyToEventId: ""
    property string replyToUserId: ""
    property string replyToDisplayName: ""

    property bool longLoading: false

    readonly property string userId: userRoomId[0]
    readonly property string roomId: userRoomId[1]

    readonly property QtObject userInfo:
        ModelStore.get("accounts").find(userRoomId[0])

    readonly property QtObject roomInfo:
        ModelStore.get(userRoomId[0], "rooms").find(userRoomId[1])

    readonly property bool ready: Boolean(userInfo && roomInfo)

    readonly property alias loader: loader
    readonly property alias roomPane: roomPaneLoader.item

    readonly property bool composerHasFocus:
        Boolean(loader.item && loader.item.composer.hasFocus)

    function clearReplyTo() {
        if (! replyToEventId) return

        replyToEventId     = ""
        replyToUserId      = ""
        replyToDisplayName = ""
    }

    onFocusChanged: if (focus && loader.item) loader.item.composer.takeFocus()
    onReadyChanged: longLoading = false

    HShortcut {
        sequences: window.settings.Keys.Chat.leave
        active: userInfo && userInfo.presence !== "offline"
        onActivated: window.makePopup(
            "Popups/LeaveRoomPopup.qml",
            {
                userId,
                roomId,
                roomName: roomInfo.display_name,
                inviterId: roomInfo.inviter_id,
                left: roomInfo.left,
            },
        )
    }

    Timer {
        interval: 300
        running: ! ready
        onTriggered: longLoading = true
    }

    Connections {
        target: pageLoader
        onAboutToRecycle: chat.clearReplyTo()
    }

    HLoader {
        id: loader
        anchors.rightMargin:
            ! roomPane ?
            0 :

            ready &&
            ! (
                roomPane.requireDefaultSize &&
                roomPane.minimumSize > roomPane.maximumSize &&
                ! roomPane.collapse
            ) ?
            roomPane.visibleSize :

            roomPane.calculatedSizeNoRequiredMinimum

        anchors.fill: parent
        visible: ! (ready && roomPane && roomPane.visibleSize >= chat.width)

        onLoaded: if (chat.focus) item.composer.takeFocus()

        source: ready ? "ChatPage.qml" : ""

        Behavior on anchors.rightMargin { HNumberAnimation {} }

        HLoader {
            anchors.centerIn: parent
            width: 96 * theme.uiScale
            height: width

            source: "../../Base/HBusyIndicator.qml"
            active: ready ? 0 : longLoading ? 1 : 0
            opacity: active ? 1 : 0

            Behavior on opacity { HNumberAnimation { factor: 2 } }
        }
    }

    HLoader {
        id: roomPaneLoader
        active: ready

        sourceComponent: RoomPane {
            id: roomPane

            readonly property alias appearAnimation: appearAnimation

            referenceSizeParent: chat
            maximumSize: chat.width - theme.minimumSupportedWidth * 1.5

            HNumberAnimation {
                id: appearAnimation
                target: roomPane.contentTranslation
                property: "x"
                from: -chat.width + roomPane.width
                to: 0
                easing.type: Easing.OutCirc
                factor: 2
                running: true
            }

            Connections {
                target: pageLoader
                onRecycled: roomPane.appearAnimation.restart()
            }
        }
    }
}
