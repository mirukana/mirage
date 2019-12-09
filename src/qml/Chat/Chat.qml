import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils
import "RoomSidePane"

Item {
    id: chat


    property string userId: ""
    property string roomId: ""

    property bool ready: userInfo !== "waiting" && roomInfo !== "waiting"

    readonly property var userInfo:
        Utils.getItem(modelSources["Account"] || [], "user_id", userId) ||
        "waiting"

    readonly property var roomInfo: Utils.getItem(
        modelSources[["Room", userId]] || [], "room_id", roomId
    ) || "waiting"

    readonly property alias roomSidePane: roomSidePane


    onRoomInfoChanged: {
        if (roomInfo.left) {
            // If left, the room will most likely be gone on client restart.
            // Try to switch back to the previous page.
            if (pageLoader.showPrevious()) return

            // If there wasn't any previous page, show default page.
            window.uiState.page           = "Pages/Default.qml"
            window.uiState.pageProperties = {}
            window.uiStateChanged()
        }
    }


    HLoader {
        anchors.rightMargin: roomSidePane.visibleWidth
        anchors.fill: parent
        visible: ! roomSidePane.hidden || anchors.rightMargin < width

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

    RoomSidePane {
        id: roomSidePane
        referenceSizeParent: chat
    }
}
