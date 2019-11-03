import QtQuick 2.12
import "../../Base"

HTileDelegate {
    id: memberDelegate
    spacing: roomSidePane.currentSpacing
    backgroundColor: theme.chat.roomSidePane.member.background

    image: HUserAvatar {
        clientUserId: chatPage.userId
        userId: model.user_id
        displayName: model.display_name
        mxc: model.avatar_url
        width: height
        height: memberDelegate.height
    }

    title.text: model.display_name || model.user_id
    title.color: theme.chat.roomSidePane.member.name

    subtitle.text: model.user_id
    subtitle.color: theme.chat.roomSidePane.member.subtitle
}
