// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import SortFilterProxyModel 0.2
import ".."
import "../Base"

Column {
    id: accountRooms
    // visible: account.opacity > 0


    property string userId: model.id
    readonly property HListView view: ListView.view
    readonly property int listIndex: index
    readonly property bool hide:
        mainPane.filter &&
        roomList.model.count < 1 &&
        ! utils.filterMatches(mainPane.filter, model.display_name)

    readonly property alias account: account
    readonly property alias collapsed: account.collapsed
    readonly property alias roomList: roomList


    Account {
        id: account
        width: parent.width
        view: accountRooms.view

        opacity: hide ?
                 0 :
                 collapsed && ! mainPane.filter ?
                 theme.mainPane.account.collapsedOpacity :
                 1
        scale: hide ? opacity : 1
        height: implicitHeight * (hide ? opacity : 1)

        Behavior on opacity { HNumberAnimation {} }
    }

    HListView {
        id: roomList
        width: parent.width
        height: hide ? 0 : contentHeight
        visible: ! hide
        interactive: false

        model: SortFilterProxyModel {
            sourceModel: ModelStore.get(accountRooms.userId, "rooms")

            filters: [
                ExpressionFilter {
                    expression: ! account.collapsed
                    enabled: ! mainPane.filter
                },

                ExpressionFilter {
                    expression: utils.filterMatches(
                        mainPane.filter, model.display_name,
                    )
                }
            ]
        }

        delegate: Room {
            width: roomList.width
            userId: accountRooms.userId
        }

        highlight: null  // managed by the AccountRoomsList

        Behavior on height { HNumberAnimation {} }
    }
}
