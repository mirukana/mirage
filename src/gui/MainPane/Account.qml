// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/HTile"

HTile {
    id: account
    implicitHeight: theme.baseElementsHeight
    backgroundColor: theme.accountView.account.background
    padded: false

    contentItem: ContentRow {
        tile: account

        HUserAvatar {
            id: avatar
            userId: model.id
            displayName: model.display_name
            mxc: model.avatar_url
            radius: 0
            compact: account.compact
        }

        TitleLabel {
            text: model.display_name || model.id
            color:
                hovered ?
                utils.nameColor(
                    model.display_name || model.id.substring(1),
                ) :
                theme.accountView.account.name

            Behavior on color { HColorAnimation {} }
        }

        HButton {
            id: addChat
            iconItem.small: true
            icon.name: "add-chat"
            backgroundColor: "transparent"
            toolTip.text: qsTr("Add new chat")
            onClicked: pageLoader.showPage(
                "AddChat/AddChat", {userId: model.id},
            )

            Layout.fillHeight: true
            Layout.maximumWidth:
                account.width >= 100 * theme.uiScale ?  implicitWidth : 0

            HShortcut {
                enabled: isCurrent
                sequences: window.settings.keys.addNewChat
                onActivated: addChat.clicked()
            }
        }
    }

    contextMenu: AccountContextMenu { userId: model.id }

    onLeftClicked: {
        pageLoader.showPage(
            "AccountSettings/AccountSettings", { "userId": model.id }
        )
    }


    property bool isCurrent: false


    HShortcut {
        enabled: isCurrent
        sequences: window.settings.keys.accountSettings
        onActivated: leftClicked()
    }
}
