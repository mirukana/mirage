// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import Clipboard 0.1
import "../Base"

HMenu {
    property string userId


    HMenuItem {
        icon.name: "account-settings"
        text: qsTr("Account settings")
        onClicked: pageLoader.showPage(
            "AccountSettings/AccountSettings", { "userId": userId },
        )
    }

    HMenuItem {
        icon.name: "menu-add-chat"
        text: qsTr("Add new chat")
        onClicked: pageLoader.showPage("AddChat/AddChat", {userId: userId})
    }

    HMenuItem {
        icon.name: "copy-user-id"
        text: qsTr("Copy user ID")
        onTriggered: Clipboard.text = userId
    }

    HMenuItemPopupSpawner {
        icon.name: "sign-out"
        icon.color: theme.colors.negativeBackground
        text: qsTr("Sign out")

        popup: "Popups/SignOutPopup.qml"
        properties: { "userId": userId }
    }
}
