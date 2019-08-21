import QtQuick 2.12
import "../../Base"

HTileDelegate {
    id: memberDelegate
    spacing: roomSidePane.currentSpacing
    rightPadding: 0
    backgroundColor: theme.sidePane.member.background

    image: HUserAvatar {
        userId: model.user_id
        displayName: model.display_name
        avatarUrl: model.avatar_url
    }

    title.color: theme.sidePane.member.name
    title.text: model.display_name || model.user_id
}
