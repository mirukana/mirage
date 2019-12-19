// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "RoomPane"

Item {
    id: chat
    onFocusChanged: if (focus && loader.item) loader.item.composer.takeFocus()


    property string userId: ""
    property string roomId: ""

    property bool loadingMessages: false
    property bool ready: userInfo !== "waiting" && roomInfo !== "waiting"

    readonly property var userInfo:
        utils.getItem(modelSources["Account"] || [], "user_id", userId) ||
        "waiting"

    readonly property var roomInfo: utils.getItem(
        modelSources[["Room", userId]] || [], "room_id", roomId
    ) || "waiting"

    readonly property alias loader: loader
    readonly property alias roomPane: roomPaneLoader.item


    HLoader {
        id: loader
        anchors.rightMargin: ready ? roomPane.visibleSize : 0
        anchors.fill: parent
        visible:
            ready ? ! roomPane.hidden || anchors.rightMargin < width : true
        onLoaded: if (chat.focus) item.composer.takeFocus()

        source: ready ? "ChatPage.qml" : ""

        HLoader {
            anchors.centerIn: parent
            width: 96 * theme.uiScale
            height: width

            source: opacity > 0 ? "../../Base/HBusyIndicator.qml" : ""
            opacity: ready ? 0 : 1

            Behavior on opacity { HNumberAnimation { factor: 2 } }
        }
    }

    HLoader {
        id: roomPaneLoader
        active: ready
        sourceComponent: RoomPane {
            id: roomPane
            referenceSizeParent: chat
        }
    }
}
