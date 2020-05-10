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
        roomList.showRoomAtIndex()
        if (window.settings.clearRoomFilterOnEnter) text = ""
    }

    Keys.onEscapePressed: {
        mainUI.pageLoader.forceActiveFocus()
        if (window.settings.clearRoomFilterOnEscape) text = ""
    }


    property RoomList roomList


    function toggleFocus() {
        if (filterField.activeFocus) {
            pageLoader.takeFocus()
            return
        }

        mainPane.open()
        filterField.forceActiveFocus()
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
