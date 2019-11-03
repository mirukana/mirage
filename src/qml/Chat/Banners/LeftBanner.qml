import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

Banner {
    color: theme.chat.leftBanner.background

    // TODO: avatar func auto
    avatar.userId: chatPage.userId
    avatar.displayName: chatPage.userInfo.display_name
    avatar.mxc: chatPage.userInfo.avatar_url
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
            Utils.makePopup(
                "Popups/ForgetRoomPopup.qml",
                mainUI,  // Must not be destroyed with chatPage
                {
                    userId:   chatPage.userId,
                    roomId:   chatPage.roomId,
                    roomName: chatPage.roomInfo.display_name,
                },
                obj => {
                    obj.onOk.connect(() => { button.loading = true })
                },
                false,
            )
        }
    })
}
