import QtQuick 2.12
import "../../Base"

HTileDelegate {
    id: memberDelegate
    spacing: roomSidePane.currentSpacing
    backgroundColor: theme.chat.roomSidePane.member.background

    image: HUserAvatar {
        userId: model.user_id
        displayName: model.display_name
        avatarUrl: model.avatar_url
    }

    title.text: model.display_name || model.user_id
    title.color: theme.chat.roomSidePane.member.name

    subtitle.text: model.user_id
    subtitle.color: theme.chat.roomSidePane.member.subtitle
}
