// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../Base"
import "../Base/HTile"

HColumnLayout {
    property AccountSwipeView accountSwipeView


    HButton {
        id: everyRoomButton
        icon.name: "every-room"
        toolTip.text: qsTr("Every room")
        backgroundColor: theme.accountsBar.everyRoomButtonBackground
        // onClicked: pageLoader.showPage("AddAccount/AddAccount")

        Layout.preferredHeight: theme.baseElementsHeight

        HShortcut {
            sequences: window.settings.keys.showEveryRoom
            onActivated: everyRoomButton.clicked()
        }
    }

    HListView {
        id: accountList
        clip: true
        model: ModelStore.get("accounts")
        currentIndex: accountSwipeView.currentIndex

        highlight: Item {

            Rectangle {
                anchors.fill: parent
                color: theme.accountsBar.accountList.account.selectedBackground
                opacity: theme.accountsBar.accountList.account
                              .selectedBackgroundOpacity
            }

            Rectangle {
                z: 100
                width: theme.accountsBar.accountList.account.selectedBorderSize
                height: parent.height
                color: theme.accountsBar.accountList.account.selectedBorder
            }
        }

        delegate: HTileDelegate {
            id: tile
            width: accountList.width
            backgroundColor: theme.accountsBar.accountList.account.background

            topPadding: (accountList.width - avatar.width) / 4
            bottomPadding: topPadding
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

                    radius: theme.accountsBar.accountList.account.avatarRadius
                }
            }

            onLeftClicked: accountSwipeView.currentIndex = model.index
        }

        Layout.fillWidth: true
        Layout.fillHeight: true

        HShortcut {
            sequences: window.settings.keys.goToPreviousAccount
            onActivated: accountSwipeView.decrementWrapIndex()
        }

        HShortcut {
            sequences: window.settings.keys.goToNextAccount
            onActivated: accountSwipeView.incrementWrapIndex()
        }

        Rectangle {
            anchors.fill: parent
            z: -100
            color: theme.accountsBar.accountList.background
        }
    }

    HButton {
        id: addAccountButton
        icon.name: "add-account"
        toolTip.text: qsTr("Add another account")
        backgroundColor: theme.accountsBar.addAccountButtonBackground
        onClicked: pageLoader.showPage("AddAccount/AddAccount")

        Layout.preferredHeight: theme.baseElementsHeight

        HShortcut {
            sequences: window.settings.keys.addNewAccount
            onActivated: addAccountButton.clicked()
        }
    }

    HButton {
        id: settingsButton
        backgroundColor: theme.accountsBar.settingsButtonBackground
        icon.name: "settings"
        toolTip.text: qsTr("Open config folder")

        onClicked: py.callCoro("get_config_dir", [], Qt.openUrlExternally)

        Layout.preferredHeight: theme.baseElementsHeight
    }
}
