import QtQuick 2.12
import "../../Base"

Banner {
    color: theme.chat.leftBanner.background

    // TODO: avatar func auto
    avatar.userId: chatPage.userId
    avatar.displayName: chatPage.userInfo.display_name
    avatar.avatarUrl: chatPage.userInfo.avatar_url
    labelText: qsTr("You are not part of this room anymore.")

    buttonModel: [
        {
            name: "forget",
            text: qsTr("Forget"),
            iconName: "room-forget",
            iconColor: theme.colors.negativeBackground
        }
    ]

    buttonCallbacks: ({
        forget: button => {
            button.loading = true
            py.callClientCoro(
                chatPage.userId, "room_forget", [chatPage.roomId], () => {
                    button.loading = false
                    Qt.callLater(pageLoader.showPage, "Default")
            })
        }
    })
}
