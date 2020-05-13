// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

Rectangle {
    // Hide filter field overflowing for a sec on size changes
    clip: true
    implicitHeight: theme.baseElementsHeight
    color: theme.mainPane.bottomBar.background


    property RoomList roomList
    readonly property alias addAccountButton: addAccountButton
    readonly property alias filterField: filterField


    function toggleFocus() {
        if (filterField.activeFocus) {
            pageLoader.takeFocus()
            return
        }

        mainPane.open()
        filterField.forceActiveFocus()
    }


    HRowLayout {
        anchors.fill: parent

        HButton {
            id: addAccountButton
            icon.name: "add-account"
            toolTip.text: qsTr("Add another account")
            backgroundColor: theme.mainPane.bottomBar.settingsButtonBackground
            onClicked: pageLoader.showPage("AddAccount/AddAccount")

            Layout.fillHeight: true

            HShortcut {
                sequences: window.settings.keys.addNewAccount
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

            Keys.onUpPressed: roomList.decrementCurrentIndex()
            Keys.onDownPressed: roomList.incrementCurrentIndex()

            Keys.onEnterPressed: Keys.onReturnPressed(event)
            Keys.onReturnPressed: {
                roomList.showItemAtIndex()
                if (window.settings.clearRoomFilterOnEnter) text = ""
            }

            Keys.onEscapePressed: {
                mainUI.pageLoader.forceActiveFocus()
                if (window.settings.clearRoomFilterOnEscape) text = ""
            }


            Behavior on opacity { HNumberAnimation {} }

            HShortcut {
                sequences: window.settings.keys.clearRoomFilter
                onActivated: filterField.text = ""
            }

            HShortcut {
                sequences: window.settings.keys.toggleFocusMainPane
                onActivated: toggleFocus()
            }
        }
    }
}
