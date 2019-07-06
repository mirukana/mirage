import QtQuick 2.7
import "../../Base"
import "../utils.js" as ChatJS

Banner {
    property var leftEvent: null

    color: theme.chat.leftBanner.background

    avatar.name: ChatJS.getLeftBannerAvatarName(leftEvent, chatPage.userId)
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
            Backend.clients.get(chatPage.userId).forgetRoom(chatPage.roomId)
            pageStack.clear()
        },
    }
}
