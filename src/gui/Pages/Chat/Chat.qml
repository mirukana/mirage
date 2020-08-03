// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "RoomPane"

Item {
    id: chat

    property string userId
    property string roomId

    property QtObject userInfo: null
    property QtObject roomInfo: null

    property bool ready: Boolean(userInfo && roomInfo)
    property bool longLoading: false

    property string replyToEventId: ""
    property string replyToUserId: ""
    property string replyToDisplayName: ""

    readonly property alias loader: loader
    readonly property alias roomPane: roomPaneLoader.item

    readonly property bool composerHasFocus:
        Boolean(loader.item && loader.item.composer.hasFocus)


    onFocusChanged: if (focus && loader.item) loader.item.composer.takeFocus()
    onReadyChanged: longLoading = false

    HShortcut {
        sequences: window.settings.keys.leaveRoom
        active: userInfo && userInfo.presence !== "offline"
        onActivated: window.makePopup(
            "Popups/LeaveRoomPopup.qml",
            {userId, roomId, roomName: roomInfo.display_name},
        )
    }

    HShortcut {
        sequences: window.settings.keys.forgetRoom
        active: userInfo && userInfo.presence !== "offline"
        onActivated: window.makePopup(
            "Popups/ForgetRoomPopup.qml",
            {userId, roomId, roomName: roomInfo.display_name},
        )
    }

    Timer {
        interval: 100
        running: ! userInfo
        repeat: true
        triggeredOnStart: true
        onTriggered: userInfo = ModelStore.get("accounts").find(userId)
    }

    Timer {
        interval: 100
        running: ! roomInfo
        repeat: true
        triggeredOnStart: true
        onTriggered: roomInfo = ModelStore.get(userId, "rooms").find(roomId)
    }

    Timer {
        interval: 300
        running: ! ready
        onTriggered: longLoading = true
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
            referenceSizeParent: chat
            maximumSize: chat.width - theme.minimumSupportedWidth * 1.5
        }
    }
}
