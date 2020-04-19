// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import SortFilterProxyModel 0.2
import ".."
import "../Base"

Column {
    id: accountRooms
    // visible: account.opacity > 0


    readonly property string userId: model.id
    readonly property bool firstSyncDone: model.first_sync_done
    readonly property HListView view: ListView.view
    readonly property int listIndex: index
    readonly property bool noFilterResults:
        mainPane.filter && roomList.model.count === 0

    readonly property alias account: account
    readonly property alias collapsed: account.collapsed
    readonly property alias roomList: roomList


    Account {
        id: account
        width: parent.width
        view: accountRooms.view

        opacity: collapsed || noFilterResults ?
                 theme.mainPane.listView.account.collapsedOpacity : 1
    }

    HListView {
        id: roomList
        width: parent.width
        height: contentHeight
        interactive: false

        // https://github.com/oKcerG/SortFilterProxyModel/issues/75
        model:
            mainPane.filter ? proxy :
            account.collapsed ? null :
            proxy.sourceModel

        delegate: HLoader {
            asynchronous: false
            active: index === 0 || (
                roomList.firstDelegateHeight !== 0 &&
                index >= roomList.firstIndexInView &&
                index <= roomList.lastIndexInView
            )

            width: roomList.width
            height: roomList.firstDelegateHeight

            readonly property var sourceModel: model

            sourceComponent: Room {
                width: roomList.width
                userId: accountRooms.userId
                view: roomList
                model: sourceModel
            }
        }

        highlight: null  // managed by the AccountRoomsList


        // Delete 0 must *always* be loaded, and all delegates must have the
        // same height
        property int firstDelegateHeight:
            contentItem.visibleChildren[0] ?
            contentItem.visibleChildren[0].implicitHeight :
            0

        readonly property int firstIndexInView:
            (mainPaneList.contentY - account.height - accountRooms.spacing) /
            firstDelegateHeight -
            accountRooms.y / firstDelegateHeight

        readonly property int lastIndexInView:
            firstIndexInView + mainPaneList.height / firstDelegateHeight

        readonly property bool hasActiveRoom:
            window.uiState.page === "Pages/Chat/Chat.qml" &&
            window.uiState.pageProperties.userId === userId

        readonly property var activeRoomIndex:
            hasActiveRoom ?
            model.findIndex(window.uiState.pageProperties.roomId) : null

        readonly property HSortFilterProxyModel proxy: HSortFilterProxyModel {
            sourceModel: ModelStore.get(accountRooms.userId, "rooms")

            filters: ExpressionFilter {
                expression: utils.filterMatches(
                    mainPane.filter, model.display_name,
                )
            }
        }


        Binding on currentIndex {
            value:
                roomList.hasActiveRoom ?
                (
                    roomList.activeRoomIndex === null ?
                    -1 : roomList.activeRoomIndex
                ) : -1

            when: ! view.detachedCurrentIndex
        }

        Behavior on height { HNumberAnimation {} }
    }
}
