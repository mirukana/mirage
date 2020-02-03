// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HDrawer {
    id: mainPane
    saveName: "mainPane"
    color: theme.mainPane.background
    minimumSize: theme.controls.avatar.size + theme.spacing * 2


    readonly property bool hasFocus: toolBar.filterField.activeFocus
    readonly property alias mainPaneList: mainPaneList
    readonly property alias toolBar: toolBar
    property alias filter: toolBar.roomFilter


    function toggleFocus() {
        if (toolBar.filterField.activeFocus) {
            pageLoader.takeFocus()
            return
        }

        mainPane.open()
        toolBar.filterField.forceActiveFocus()
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

        MainPaneToolBar {
            id: toolBar
            mainPaneList: mainPaneList

            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: theme.baseElementsHeight

        }
    }
}
