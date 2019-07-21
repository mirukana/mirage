// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HPage {
    id: chatPage

    property bool ready: roomInfo && ! roomInfo.loading

    property var roomInfo: null
    onRoomInfoChanged: if (! roomInfo) { pageStack.showPage("Default") }

    readonly property string userId: roomInfo.userId
    readonly property string category: roomInfo.category
    readonly property string roomId: roomInfo.roomId

    readonly property var senderInfo: users.find(userId)

    readonly property bool hasUnknownDevices: false
         //category == "Rooms" ?
         //Backend.clients.get(userId).roomHasUnknownDevices(roomId) : false

    header: RoomHeader {
        id: roomHeader
        displayName: roomInfo.displayName
        topic: roomInfo.topic

        clip: height < implicitHeight
        width: parent.width
        height: ready ? implicitHeight : 0
        Behavior on height { HNumberAnimation {} }
    }

    page.leftPadding: 0
    page.rightPadding: 0


    Loader {
        Timer {
            interval: 200
            repeat: true
            running: ! ready
            onTriggered: {
                let info = rooms.find(userId, category, roomId)
                if (! info.loading) { roomInfo = Qt.binding(() => info) }
            }
        }

        source: ready ? "ChatSplitView.qml" : "../Base/HBusyIndicator.qml"

        Layout.fillWidth: ready
        Layout.fillHeight: ready
        Layout.alignment: Qt.AlignCenter
    }
}
