import QtQuick 2.12
import "../../Base"

Banner {
    property string userId: ""

    color: theme.chat.leftBanner.background

    // TODO: avatar func auto
    avatar.userId: userId
    labelText: qsTr("You are not part of this room anymore.")

    buttonModel: [
        {
            name: "forget",
            text: qsTr("Forget"),
            iconName: "forget-room",
        }
    ]

    buttonCallbacks: ({
        forget: button => {
            button.loading = true
            py.callClientCoro(
                chatPage.userId, "room_forget", [chatPage.roomId], () => {
                    button.loading = false
            })
        }
    })
}
