// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HDrawer {
    id: mainPane
    saveName: "mainPane"
    background: null
    minimumSize: theme.controls.avatar.size + theme.spacing * 2

    readonly property alias accountsBar: accountsBar
    readonly property alias roomList: roomList
    readonly property alias filterRoomsField: filterRoomsField


    Behavior on opacity { HNumberAnimation {} }

    Binding on visible {
        value: false
        when: ! mainUI.accountsPresent
    }

    HColumnLayout {
        anchors.fill: parent

        TopBar {
            Layout.fillWidth: true
            Layout.preferredHeight: theme.baseElementsHeight
        }

        AccountsBar {
            id: accountsBar
            roomList: roomList

            Layout.fillWidth: true
            Layout.maximumHeight: parent.height / 3
        }

        RoomList {
            id: roomList
            clip: true
            filter: filterRoomsField.text

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        FilterRoomsField {
            id: filterRoomsField
            roomList: roomList

            Layout.fillWidth: true
        }
    }
}
