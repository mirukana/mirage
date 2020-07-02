// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import Clipboard 0.1
import "../Base"

HMenu {
    property string userId
    property string presence
    property bool   firstSyncDone


    function setPresence(presence) {
        py.callClientCoro(userId, "set_presence", [presence])
    }


    HMenuItem {
        icon.name: "account-settings"
        text: qsTr("Account settings")
        onTriggered: pageLoader.showPage(
            "AccountSettings/AccountSettings", { "userId": userId },
        )
    }

    HMenuItem {
        icon.name: "menu-add-chat"
        text: qsTr("Add new chat")
        onTriggered: pageLoader.showPage("AddChat/AddChat", {userId: userId})
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

    HMenuSeparator { }

    HMenuItem {
        enabled: presence !== "online" && firstSyncDone
        icon.name: "user-presence"
        icon.color: theme.controls.presence.online
        text: qsTr("Online")
        onTriggered: setPresence("online")
    }

    HMenuItem {
        enabled: presence !== "unavailable" && firstSyncDone
        icon.name: "user-presence"
        icon.color: theme.controls.presence.unavailable
        text: qsTr("Unavailable")
        onTriggered: setPresence("unavailable")
    }

    HMenuItem {
        enabled: presence !== "invisible" && firstSyncDone
        icon.name: "user-presence"
        icon.color: theme.controls.presence.offline
        text: qsTr("Invisible")
        onTriggered: setPresence("invisible")
    }

    HMenuItem {
        enabled: presence !== "offline" && firstSyncDone
        icon.name: "user-presence"
        icon.color: theme.controls.presence.offline
        text: qsTr("Offline")
        onTriggered: setPresence("offline")
    }
}
