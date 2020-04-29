// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."
import "../Base"

HTextField {
    id: filterField
    saveName: "roomFilterField"
    implicitHeight: theme.baseElementsHeight

    placeholderText: qsTr("Filter rooms")
    backgroundColor: theme.accountView.bottomBar.filterFieldBackground
    bordered: false
    opacity: width >= 16 * theme.uiScale ? 1 : 0

    Keys.onUpPressed: roomList.decrementCurrentIndex()
    Keys.onDownPressed: roomList.incrementCurrentIndex()

    Keys.onEnterPressed: Keys.onReturnPressed(event)
    Keys.onReturnPressed: {
        if (window.settings.clearRoomFilterOnEnter) text = ""
        roomList.showRoomAtIndex()
    }

    Keys.onEscapePressed: {
        if (window.settings.clearRoomFilterOnEscape) text = ""
        mainUI.pageLoader.forceActiveFocus()
    }


    property RoomList roomList


    Behavior on opacity { HNumberAnimation {} }

    HShortcut {
        sequences: window.settings.keys.clearRoomFilter
        onActivated: filterField.text = ""
    }

    HShortcut {
        sequences: window.settings.keys.toggleFocusMainPane
        onActivated: {
            if (filterField.activeFocus) {
                pageLoader.takeFocus()
                return
            }

            mainPane.open()
            filterField.forceActiveFocus()
        }
    }
}
