// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../Base"
import "../Base/HTile"

HColumnLayout {
    property RoomList roomList


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

    HListView {
        id: accountList
        clip: true
        currentIndex:
            roomList.count === 0 || roomList.currentIndex === -1 ?
            -1 :
            model.findIndex(
                roomList.model.get(roomList.currentIndex).for_account, -1,
            )

        model: ModelStore.get("matching_accounts")

        delegate: HTileDelegate {
            id: tile
            width: accountList.width
            backgroundColor:
                theme.accountsBar.accountList.account.background

            topPadding: (accountList.width - avatar.width) / 4
            bottomPadding: topPadding
            leftPadding: 0
            rightPadding: leftPadding

            contentItem: Item {
                id: tileContent
                implicitHeight: avatar.height

                HUserAvatar {
                    id: avatar
                    anchors.horizontalCenter: parent.horizontalCenter
                    userId: model.id
                    displayName: model.display_name
                    mxc: model.avatar_url
                    // compact: tile.compact

                    radius:
                        theme.accountsBar.accountList.account.avatarRadius
                }

                MessageIndicator {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    indicatorTheme:
                        theme.accountView.account.unreadIndicator
                    unreads: model.total_unread
                    mentions: model.total_mentions
                }

                HLoader {
                    anchors.fill: parent
                    opacity: model.first_sync_done ? 0 : 1

                    active: opacity > 0
                    sourceComponent: Rectangle {
                        color: utils.hsluv(0, 0, 0, 0.5)

                        HBusyIndicator {
                            anchors.centerIn: parent
                            width: tileContent.width / 2
                            height: width
                        }
                    }

                    Behavior on opacity { HNumberAnimation {} }
                }
            }

            contextMenu: AccountContextMenu { userId: model.id }

            onLeftClicked: {
                model.id in roomList.sectionIndice ?
                roomList.goToAccount(model.id) :
                pageLoader.showPage("AddChat/AddChat", {userId: model.id})
            }
        }

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

        Layout.fillWidth: true
        Layout.fillHeight: true

        HShortcut {
            sequences: window.settings.keys.goToPreviousAccount
            onActivated: {
                accountList.decrementCurrentIndex()
                accountList.currentItem.leftClicked()
            }
        }

        HShortcut {
            sequences: window.settings.keys.goToNextAccount
            onActivated: {
                accountList.incrementCurrentIndex()
                accountList.currentItem.leftClicked()
            }
        }

        Rectangle {
            anchors.fill: parent
            z: -100
            color: theme.accountsBar.accountList.background
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
