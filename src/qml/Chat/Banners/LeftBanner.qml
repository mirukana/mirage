import QtQuick 2.7
import "../../Base"

Banner {
    property string userId: ""
    readonly property var userInfo: users.getUser(userId)

    color: theme.chat.leftBanner.background

    // TODO: avatar func auto
    avatar.userId: userId
    avatar.imageUrl: users.getUser(userId).avatarUrl
    labelText: qsTr("You are not part of this room anymore.")

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
            py.callClientCoro(
                chatPage.userId, "room_forget", [chatPage.roomId], {},
                function() {
                    button.loading = false
                    pageStack.clear()
                }
            )
        },
    }
}
