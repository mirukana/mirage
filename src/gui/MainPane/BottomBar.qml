// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

Rectangle {
    property RoomList roomList
    readonly property alias addAccountButton: addAccountButton
    readonly property alias filterField: filterField

    // Hide filter field overflowing for a sec on size changes
    clip: true
    implicitHeight: theme.baseElementsHeight
    color: theme.mainPane.bottomBar.background

    HRowLayout {
        anchors.fill: parent

        HButton {
            id: addAccountButton
            icon.name: "add-account"
            toolTip.text: qsTr("Add another account")
            backgroundColor: theme.mainPane.bottomBar.settingsButtonBackground
            onClicked: {
                pageLoader.show("Pages/AddAccount/AddAccount.qml")
                roomList.startCorrectItemSearch()
            }

            Layout.fillHeight: true

            HShortcut {
                sequences: window.settings.Keys.Accounts.add
                onActivated: addAccountButton.clicked()
            }
        }

        HTextField {
            id: filterField
            saveName: "roomFilterField"

            placeholderText: qsTr("Filter rooms")
            backgroundColor: theme.mainPane.bottomBar.filterFieldBackground
            bordered: false
            opacity: width >= 16 * theme.uiScale ? 1 : 0

            Layout.fillWidth: true
            Layout.fillHeight: true

            Keys.forwardTo: [roomList]
            Keys.priority: Keys.AfterItem

            Keys.onTabPressed: roomList.incrementCurrentIndex()
            Keys.onBacktabPressed: roomList.decrementCurrentIndex()
            Keys.onEnterPressed: Keys.onReturnPressed(event)
            Keys.onReturnPressed: {
                roomList.showItemAtIndex()
                if (window.settings.RoomList.enter_clears_filter) text = ""
            }

            Keys.onMenuPressed:
                if (roomList.currentItem)
                    roomList.currentItem.doRightClick(false)

            Keys.onEscapePressed: {
                mainPane.toggleFocus()
                if (window.settings.RoomList.escape_clears_filter) text = ""
            }

            Behavior on opacity { HNumberAnimation {} }

            HShortcut {
                sequences: window.settings.Keys.Rooms.clear_filter
                onActivated: filterField.text = ""
            }

            HShortcut {
                sequences: window.settings.Keys.Rooms.focus_filter
                onActivated: mainPane.toggleFocus()
            }
        }
    }
}
