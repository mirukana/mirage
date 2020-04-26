// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../Base"
import "../Base/HTile"

HColumnLayout {
    property RoomPane roomContainer


    HButton {
        id: settingsButton
        backgroundColor: "transparent"
        icon.name: "settings"
        toolTip.text: qsTr("Open config folder")

        onClicked: py.callCoro("get_config_dir", [], Qt.openUrlExternally)

        Layout.preferredHeight: theme.baseElementsHeight
    }

    HListView {
        id: accountList
        model: ModelStore.get("accounts")
        currentIndex: roomContainer.currentIndex

        delegate: HTileDelegate {
            id: tile
            width: accountList.width
            backgroundColor: theme.mainPane.listView.account.background
            leftPadding: 0
            rightPadding: leftPadding

            contentItem: Item {
                implicitHeight: avatar.height

                HUserAvatar {
                    id: avatar
                    anchors.horizontalCenter: parent.horizontalCenter
                    userId: model.id
                    displayName: model.display_name
                    mxc: model.avatar_url
                    // compact: account.compact

                    radius: theme.mainPane.listView.account.avatarRadius
                }
            }

            onLeftClicked: roomContainer.currentIndex = model.index
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    HButton {
        id: addAccountButton
        icon.name: "add-account"
        toolTip.text: qsTr("Add another account")
        backgroundColor: theme.mainPane.bottomBar.settingsButtonBackground
        onClicked: pageLoader.showPage("AddAccount/AddAccount")

        Layout.preferredHeight: theme.baseElementsHeight

        HShortcut {
            sequences: window.settings.keys.addNewAccount
            onActivated: addAccountButton.clicked()
        }
    }
}
