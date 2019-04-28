import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../Base" as Base
import "utils.js" as ChatJS

Banner {
    property var leftEvent: null

    color: Base.HStyle.chat.leftBanner.background

    onButtonClicked: if (signalId === "forget") {
        chatPage.canLoadPastEvents = false
        pageStack.clear()
    }

    avatarName: ChatJS.getLeftBannerAvatarName(leftEvent, chatPage.userId)
    labelText: ChatJS.getLeftBannerText(leftEvent)

    buttonModel: [
        {
            signalId: "forget",
            text: "Forget",
            iconName: "forget_room",
            //iconColor: Qt.hsla(0.95, 0.9, 0.35, 1),
            clientFunction: "forgetRoom",
            clientArgs: [chatPage.roomId],
        }
    ]
}
