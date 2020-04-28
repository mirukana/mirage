// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."
import "../Base"

HLoader {
    id: loader
    active:
        HSwipeView.isCurrentItem ||
        HSwipeView.isNextItem ||
        HSwipeView.isPreviousItem

    readonly property bool isCurrent: HSwipeView.isCurrentItem

    sourceComponent: HColumnLayout {
        id: column

        readonly property QtObject accountModel: model
        readonly property alias roomList: roomList

        Account {
            id: account
            isCurrent: loader.isCurrent

            Layout.fillWidth: true
        }

        RoomList {
            id: roomList
            clip: true
            accountModel: column.accountModel
            roomPane: swipeView
            isCurrent: loader.isCurrent

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        FilterRoomsField {
            roomList: roomList
            Layout.fillWidth: true
        }
    }
}
