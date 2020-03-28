// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

Rectangle {
    // Hide filter field overflowing for a sec on size changes
    clip: true
    color: theme.mainPane.bottomBar.background


    property AccountRoomsList mainPaneList
    readonly property alias addAccountButton: addAccountButton
    readonly property alias filterField: filterField
    property alias roomFilter: filterField.text


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

            Keys.onUpPressed: mainPaneList.previous(false)  // do not activate
            Keys.onDownPressed: mainPaneList.next(false)

            Keys.onEnterPressed: Keys.onReturnPressed(event)
            Keys.onReturnPressed: {
                if (event.modifiers & Qt.ShiftModifier) {
                    mainPaneList.toggleCollapseAccount()
                    return
                }

                if (window.settings.clearRoomFilterOnEnter) {
                    mainPaneList.setCollapseAccount(false)
                    text = ""
                }

                mainPaneList.requestActivate()
            }

            Keys.onEscapePressed: {
                if (window.settings.clearRoomFilterOnEscape) text = ""
                mainUI.pageLoader.forceActiveFocus()
            }

            Behavior on opacity { HNumberAnimation {} }

            HShortcut {
                sequences: window.settings.keys.clearRoomFilter
                onActivated: filterField.text = ""
            }
        }
    }
}
