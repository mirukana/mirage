// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../Base"
import "../../../Base/HTile"

HTile {
    id: root

    property bool colorName: hovered

    backgroundColor: "transparent"
    contentItem: ContentRow {
        tile: root

        HUserAvatar {
            id: avatar
            userId: model.id
            displayName: model.display_name
            mxc: model.avatar_url
            compact: root.compact
            radius: theme.chat.userAutoCompletion.avatarsRadius

            implicitHeight:
                compact ?
                theme.controls.avatar.compactSize :
                theme.controls.avatar.size / 1.5
        }

        TitleLabel {
            textFormat: TitleLabel.StyledText
            text:
                (model.display_name || model.id) + (
                    model.display_name ?
                    "&nbsp;".repeat(2) + utils.htmlColorize(
                        model.id, theme.chat.userAutoCompletion.userIds,
                    ) :
                    ""
                )

            color:
                root.colorName ?
                utils.nameColor(model.display_name || model.id.substring(1)) :
                theme.chat.userAutoCompletion.displayNames

            Behavior on color { HColorAnimation {} }
        }
    }
}
