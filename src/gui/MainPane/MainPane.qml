// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HDrawer {
    id: mainPane
    saveName: "mainPane"
    background: Rectangle { color: theme.mainPane.background }
    minimumSize: theme.controls.avatar.size + theme.spacing * 2

    readonly property alias accountBar: accountBar
    readonly property alias roomList: roomList
    readonly property alias bottomBar: bottomBar


    Behavior on opacity { HNumberAnimation {} }

    Binding on visible {
        value: false
        when: ! mainUI.accountsPresent
    }

    HColumnLayout {
        anchors.fill: parent

        TopBar {
            Layout.fillWidth: true
        }

        AccountBar {
            id: accountBar
            roomList: roomList

            Layout.fillWidth: true
            Layout.maximumHeight: parent.height / 3
        }

        RoomList {
            id: roomList
            clip: true
            filter: bottomBar.filterField.text

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        BottomBar {
            id: bottomBar
            roomList: roomList

            Layout.fillWidth: true
        }
    }
}
