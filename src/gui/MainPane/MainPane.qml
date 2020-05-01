// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HDrawer {
    id: mainPane
    saveName: "mainPane"
    background: null
    minimumSize:
        accountBar.width + theme.controls.avatar.size + theme.spacing * 2

    readonly property alias accountBar: accountBar
    readonly property alias roomList: roomList
    readonly property alias filterRoomsField: filterRoomsField


    Behavior on opacity { HNumberAnimation {} }

    Binding on visible {
        value: false
        when: ! mainUI.accountsPresent
    }

    HRowLayout {
        anchors.fill: parent

        AccountsBar {
            id: accountBar
            roomList: roomList

            Layout.fillWidth: false
        }

        HColumnLayout {
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
}
