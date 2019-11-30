import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

HTileDelegate {
    id: memberDelegate
    spacing: roomSidePane.currentSpacing
    backgroundColor: theme.chat.roomSidePane.member.background

    image: HUserAvatar {
        userId: model.user_id
        displayName: model.display_name
        mxc: model.avatar_url
        powerLevel: model.power_level
    }

    title.text: model.display_name || model.user_id
    title.color:
        memberDelegate.hovered ?
        Utils.nameColor(model.display_name || model.user_id.substring(1)) :
        theme.chat.roomSidePane.member.name

    subtitle.text: model.user_id
    subtitle.color: theme.chat.roomSidePane.member.subtitle


    Behavior on title.color { HColorAnimation {} }
}
