// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HDrawer {
    id: mainPane
    saveName: "mainPane"
    color: theme.mainPane.background
    minimumSize: theme.controls.avatar.size + theme.spacing * 2

    onHasFocusChanged:
        if (! hasFocus) mainPaneList.detachedCurrentIndex = false


    readonly property bool hasFocus: bottomBar.filterField.activeFocus
    readonly property alias mainPaneList: mainPaneList
    readonly property alias bottomBar: bottomBar
    property alias filter: bottomBar.roomFilter


    function toggleFocus() {
        if (bottomBar.filterField.activeFocus) {
            pageLoader.takeFocus()
            return
        }

        mainPane.open()
        bottomBar.filterField.forceActiveFocus()
    }

    function addccount() {
        bottomBar.addAccountButton.clicked()
    }


    Behavior on opacity { HNumberAnimation {} }

    Binding on visible {
        value: false
        when: ! mainUI.accountsPresent
    }

    HColumnLayout {
        anchors.fill: parent

        AccountRoomsList {
            id: mainPaneList
            clip: true

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        BottomBar {
            id: bottomBar
            mainPaneList: mainPaneList

            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: theme.baseElementsHeight

        }
    }
}
