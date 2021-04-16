// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import "../Base"

HMenu {
    id: root

    property string userId
    property string presence
    property string statusMsg

    signal wentToAccountPage()

    function setPresence(presence, statusMsg=undefined) {
        py.callClientCoro(userId, "set_presence", [presence, statusMsg])
    }

    function statusFieldApply(newStatus=null) {
        if (newStatus === null) newStatus = statusField.editText.trim()

        if (newStatus) {
            const existing = statusRepeater.items.indexOf(newStatus)
            if (existing !== -1) statusRepeater.items.splice(existing, 1)

            statusRepeater.items.unshift(newStatus)
            statusRepeater.items.length = Math.min(statusRepeater.count, 5)
            statusRepeater.itemsChanged()
            window.saveState(statusRepeater)
        }

        setPresence(presence, newStatus)
        close()
    }

    onOpened: statusField.forceActiveFocus()

    HLabeledItem {
        id: statusMsgLabel
        enabled: presence && presence !== "offline"
        width: parent.width
        height: visible ? implicitHeight : 0

        label.text: qsTr("Status message:")
        label.horizontalAlignment: Qt.AlignHCenter
        label.leftPadding: theme.spacing
        label.rightPadding: label.leftPadding
        label.topPadding: theme.spacing / 2
        label.bottomPadding: label.topPadding

        HRowLayout {
            width: parent.width

            HComboBox {
                // We use a ComboBox disguised as a field for the
                // autosuggestion-as-we-type feature

                id: statusField
                editable: true
                indicator: null
                popup: null
                model: statusRepeater.model
                currentIndex: statusRepeater.items.indexOf(
                    root.currentIndex !== -1 &&
                    root.itemAt(root.currentIndex).isStatus ?
                    root.itemAt(root.currentIndex).text :
                    root.statusMsg
                )

                field.placeholderText: presence ? "" : "Unsupported server"
                field.maximumLength: 255

                onAccepted: root.statusFieldApply()
                onActiveFocusChanged: if (activeFocus) field.selectAll()

                Keys.onBacktabPressed: event => Keys.upPressed(event)
                Keys.onTabPressed: event => Keys.downPressed(event)

                Keys.onUpPressed: signOutItem.forceActiveFocus()
                Keys.onDownPressed:
                    (statusRepeater.itemAt(0) || onlineItem).forceActiveFocus()

                Layout.fillWidth: true
            }

            HButton {
                id: button
                visible: presence

                icon.name: "apply"
                icon.color: theme.colors.positiveBackground
                onClicked: root.statusFieldApply()

                Layout.fillHeight: true
            }
        }
    }

    HMenuSeparator {}

    Repeater {
        id: statusRepeater

        // Separate property instead of setting model directly so that we can
        // manipulate this as a JS list, not a QQmlModel
        property var items: window.getState(this, "items", [])

        readonly property string saveName: "lastStatus"
        readonly property string saveId: "ALL"
        readonly property var saveProperties: ["items"]

        model: items

        delegate: HMenuItem {
            readonly property bool isStatus: true

            icon.name: "previously-set-status"
            text: modelData
            onTriggered: root.statusFieldApply(text)

            Keys.onBacktabPressed: event => Keys.upPressed(event)

            Keys.onUpPressed: event => {
                event.accepted = index === 0
                if (event.accepted) statusField.forceActiveFocus()
            }
        }
    }

    HMenuSeparator { visible: statusRepeater.count > 0 }

    HMenuItem {
        id: onlineItem
        icon.name: "presence-online"
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
        icon.name: "presence-invisible"
        icon.color: theme.controls.presence.offline
        text: qsTr("Invisible")
        onTriggered: setPresence("invisible")
    }

    HMenuItem {
        icon.name: "presence-offline"
        icon.color: theme.controls.presence.offline
        text: qsTr("Offline")
        onTriggered: setPresence("offline")
    }

    HMenuSeparator {
        visible: statusMsgLabel.visible
        height: visible ? implicitHeight : 0
    }

    HMenuItem {
        icon.name: "account-settings"
        text: qsTr("Account settings")
        onTriggered: {
            pageLoader.show(
                "Pages/AccountSettings/AccountSettings.qml",
                { "userId": userId },
            )
            wentToAccountPage()
        }
    }

    HMenuItem {
        icon.name: "menu-add-chat"
        text: qsTr("Add new chat")
        onTriggered: {
            pageLoader.show("Pages/AddChat/AddChat.qml", {userId: userId})
            wentToAccountPage()
        }
    }

    HMenuItem {
        icon.name: "copy-user-id"
        text: qsTr("Copy user ID")
        onTriggered: Clipboard.text = userId
    }

    HMenuItemPopupSpawner {
        id: signOutItem
        icon.name: "sign-out"
        icon.color: theme.colors.negativeBackground
        text: qsTr("Sign out")

        popup: "Popups/SignOutPopup.qml"
        properties: { "userId": userId }

        Keys.onDownPressed: statusField.forceActiveFocus()
    }
}
