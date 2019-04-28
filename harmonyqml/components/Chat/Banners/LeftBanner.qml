import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../../Base"
import "../utils.js" as ChatJS

Banner {
    property var leftEvent: null

    color: HStyle.chat.leftBanner.background

    avatarName: ChatJS.getLeftBannerAvatarName(leftEvent, chatPage.userId)
    labelText: ChatJS.getLeftBannerText(leftEvent)

    buttonModel: [
        {
            name: "forget",
            text: qsTr("Forget"),
            iconName: "forget_room",
        }
    ]

    buttonCallbacks: {
        "forget": function(button) {
            button.loading = true
            chatPage.canLoadPastEvents = false
            Backend.clientManager.clients[chatPage.userId].forgetRoom(
                chatPage.roomId
            )
            pageStack.clear()
        },
    }
}
