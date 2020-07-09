// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import "../Base"

HMenu {
    id: accountMenu

    property string userId
    property string presence
    property string statusMsg

    onOpened: statusText.forceActiveFocus()


    function setPresence(presence, statusMsg = undefined) {
        py.callClientCoro(userId, "set_presence", [presence, statusMsg])
    }


    HMenuItem {
        icon.name: "presence"
        icon.color: theme.controls.presence.online
        text: qsTr("Online")
        onTriggered: setPresence("online")
    }

    HMenuItem {
        enabled: presence
        icon.name: "presence-busy"
        icon.color: theme.controls.presence.unavailable
        text: qsTr("Unavailable")
        onTriggered: setPresence("unavailable")
    }

    HMenuItem {
        icon.name: "presence-offline"
        icon.color: theme.controls.presence.offline
        text: qsTr("Offline")
        onTriggered: setPresence("offline")
    }

    HMenuItem {
        enabled: presence
        icon.name: "presence-invisible"
        icon.color: theme.controls.presence.offline
        text: qsTr("Invisible")
        onTriggered: setPresence("invisible")
    }

    HMenuSeparator { }

    HLabeledItem {
        id: statusMsgLabel
        enabled: presence && presence !== "offline"
        width: parent.width
        height: visible ? implicitHeight : 0
        label.text: qsTr("Status message:")
        label.horizontalAlignment: Qt.AlignHCenter

        HRowLayout {
            width: parent.width

            HTextField {
                id: statusText
                maximumLength: 255
                horizontalAlignment: Qt.AlignHCenter
                onAccepted: {
                    setPresence(presence, statusText.text)
                    accountMenu.close()
                }

                defaultText: statusMsg
                placeholderText: ! presence ? "Unsupported server" : ""

                Layout.fillWidth: true
            }

            HButton {
                id: button
                visible: presence

                icon.name: "apply"
                icon.color: theme.colors.positiveBackground
                onClicked: {
                    setPresence(presence, statusText.text)
                    accountMenu.close()
                }

                Layout.fillHeight: true
            }
        }
    }

    HMenuSeparator {
        visible: statusMsgLabel.visible
        height: visible ? implicitHeight : 0
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
}
