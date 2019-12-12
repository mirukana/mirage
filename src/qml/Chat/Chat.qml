import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils
import "RoomPane"

Item {
    id: chat
    onFocusChanged: if (focus && loader.item) loader.item.composer.takeFocus()


    property string userId: ""
    property string roomId: ""

    property bool ready: userInfo !== "waiting" && roomInfo !== "waiting"

    readonly property var userInfo:
        Utils.getItem(modelSources["Account"] || [], "user_id", userId) ||
        "waiting"

    readonly property var roomInfo: Utils.getItem(
        modelSources[["Room", userId]] || [], "room_id", roomId
    ) || "waiting"

    readonly property alias loader: loader
    readonly property alias roomPane: roomPane


    HLoader {
        id: loader
        anchors.rightMargin: roomPane.visibleSize
        anchors.fill: parent
        visible: ! roomPane.hidden || anchors.rightMargin < width
        onLoaded: if (chat.focus) item.composer.takeFocus()

        source: ready ? "ChatPage.qml" : ""

        HLoader {
            anchors.centerIn: parent
            width: 96 * theme.uiScale
            height: width

            source: opacity > 0 ? "../Base/HBusyIndicator.qml" : ""
            opacity: ready ? 0 : 1

            Behavior on opacity { HOpacityAnimator { factor: 2 } }
        }
    }

    RoomPane {
        id: roomPane
        referenceSizeParent: chat
    }
}
