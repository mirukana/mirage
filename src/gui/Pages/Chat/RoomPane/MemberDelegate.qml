// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import Clipboard 0.1
import "../../../Base"

HTileDelegate {
    id: memberDelegate
    backgroundColor: theme.chat.roomPane.listView.member.background
    contentOpacity:
        model.invited ? theme.chat.roomPane.listView.member.invitedOpacity : 1

    image: HUserAvatar {
        userId: model.id
        displayName: model.display_name
        mxc: model.avatar_url
        powerLevel: model.power_level
        shiftMembershipIconPosition: ! roomPane.collapsed
        invited: model.invited
        compact: memberDelegate.compact
    }

    title.text: model.display_name || model.id
    title.color:
        memberDelegate.hovered ?
        utils.nameColor(model.display_name || model.id.substring(1)) :
        theme.chat.roomPane.listView.member.name

    subtitle.text: model.display_name ? model.id : ""
    subtitle.color: theme.chat.roomPane.listView.member.subtitle

    contextMenu: HMenu {
        HMenuItem {
            icon.name: "copy-user-id"
            text: qsTr("Copy user ID")
            onTriggered: Clipboard.text = model.id
        }
    }


    Behavior on title.color { HColorAnimation {} }
    Behavior on contentOpacity { HNumberAnimation {} }
    Behavior on spacing { HNumberAnimation {} }

    Binding on spacing {
        value: (roomPane.minimumSize - loadedImage.width) / 2
        when: loadedImage &&
              roomPane.width < loadedImage.width + theme.spacing * 2
    }
}
