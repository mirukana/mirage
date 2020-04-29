// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
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
            userId: accountModel.id
            displayName: accountModel.display_name
            mxc: accountModel.avatar_url
            radius: 0
        }

        TitleLabel {
            text: accountModel.display_name || accountModel.id
            color:
                hovered ?
                utils.nameColor(
                    accountModel.display_name || accountModel.id.substring(1),
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
                "AddChat/AddChat", {userId: accountModel.id},
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

    contextMenu: HMenu {
        HMenuItem {
            icon.name: "copy-user-id"
            text: qsTr("Copy user ID")
            onTriggered: Clipboard.text = accountModel.id
        }

        HMenuItemPopupSpawner {
            icon.name: "sign-out"
            icon.color: theme.colors.negativeBackground
            text: qsTr("Sign out")

            popup: "Popups/SignOutPopup.qml"
            properties: { "userId": accountModel.id }
        }
    }

    onLeftClicked: {
        pageLoader.showPage(
            "AccountSettings/AccountSettings", { "userId": accountModel.id }
        )
    }


    property var accountModel
    property bool isCurrent: false


    Behavior on leftPadding { HNumberAnimation {} }
    Behavior on topPadding { HNumberAnimation {} }

    Binding on leftPadding {
        value: (mainPane.minimumSize - avatar.width) / 2
        when: mainPane.small
    }

    Binding on topPadding {
        value: theme.spacing
        when: mainPane.small
    }

    Binding on bottomPadding {
        value: theme.spacing
        when: mainPane.small
    }


    HShortcut {
        enabled: isCurrent
        sequences: window.settings.keys.accountSettings
        onActivated: leftClicked()
    }
}
