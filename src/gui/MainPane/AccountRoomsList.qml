// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import SortFilterProxyModel 0.2
import ".."
import "../Base"

HListView {
    id: mainPaneList
    model: ModelStore.get("accounts")

    delegate: AccountRoomsDelegate {
        width: mainPaneList.width
        height: childrenRect.height
    }


    function previous(activate=true) {
        decrementCurrentIndex()
        if (activate) activateLimiter.restart()
    }

    function next(activate=true) {
        incrementCurrentIndex()
        if (activate) activateLimiter.restart()
    }

    function activate() {
        currentItem.item.activated()
    }

    function accountSettings() {
        if (! currentItem) incrementCurrentIndex()

        pageLoader.showPage(
            "AccountSettings/AccountSettings",
            {userId: currentItem.item.delegateModel.user_id},
        )
    }

    function addNewChat() {
        if (! currentItem) incrementCurrentIndex()

        pageLoader.showPage(
            "AddChat/AddChat",
            {userId: currentItem.item.delegateModel.user_id},
        )
    }

    function toggleCollapseAccount() {
        if (mainPane.filter) return

        if (! currentItem) incrementCurrentIndex()

        if (currentItem.item.delegateModel.type === "Account") {
            currentItem.item.toggleCollapse()
            return
        }

        for (let i = 0;  i < model.source.length; i++) {
            let item = model.source[i]

            if (item.type === "Account" && item.user_id ==
                currentItem.item.delegateModel.user_id)
            {
                currentIndex = i
                currentItem.item.toggleCollapse()
            }
        }
    }


    Timer {
        id: activateLimiter
        interval: 300
        onTriggered: activate()
    }
}
