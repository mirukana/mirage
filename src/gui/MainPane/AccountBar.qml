// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import ".."
import "../Base"
import "../Base/HTile"


Rectangle {
    implicitHeight: accountList.count >= 2 ? accountList.contentHeight : 0
    color: theme.mainPane.accountBar.background


    property RoomList roomList
    readonly property alias accountList: accountList


    Behavior on implicitHeight { HNumberAnimation {} }

    HGridView {
        id: accountList
        anchors.centerIn: parent
        width: Math.min(cellWidth * count, parent.width)
        height: parent.height

        clip: true
        cellWidth: theme.controls.avatar.size + theme.spacing
        cellHeight: cellWidth
        currentIndex:
            roomList.count === 0 || roomList.currentIndex === -1 ?
            -1 :
            model.findIndex(
                roomList.model.get(roomList.currentIndex).for_account ||
                roomList.model.get(roomList.currentIndex).id,
                -1,
            )

        model: ModelStore.get("matching_accounts")

        delegate: Account {
            width: accountList.cellWidth
            height: accountList.cellHeight
            padded: false
            compact: false
            filterActive: Boolean(roomList.filter)

            title.visible: false
            addChat.visible: false
            expand.visible: false

            onLeftClicked: roomList.goToAccount(model.id)
        }

        highlight: Item {
            readonly property alias border: border

            Rectangle {
                anchors.fill: parent
                color: theme.mainPane.accountBar.account.selectedBackground
                opacity: theme.mainPane.accountBar.account
                              .selectedBackgroundOpacity
            }

            Rectangle {
                id: border
                anchors.bottom: parent.bottom
                width: parent.width
                height:
                    theme.mainPane.accountBar.account.selectedBorderSize
                color: theme.mainPane.accountBar.account.selectedBorder
            }
        }


        HShortcut {
            sequences: window.settings.keys.goToPreviousAccount
            onActivated: {
                accountList.moveCurrentIndexLeft()
                accountList.currentItem.leftClicked()
            }
        }

        HShortcut {
            sequences: window.settings.keys.goToNextAccount
            onActivated: {
                accountList.moveCurrentIndexRight()
                accountList.currentItem.leftClicked()
            }
        }
    }
}
