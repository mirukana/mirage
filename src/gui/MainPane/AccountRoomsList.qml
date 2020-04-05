// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import ".."
import "../Base"

HListView {
    id: mainPaneList
    model: ModelStore.get("accounts")
    spacing: mainPane.small ? theme.spacing : 0

    delegate: AccountRoomsDelegate {
        width: mainPaneList.width
        height: childrenRect.height
    }

    // Must handle the highlight's position and size manually because
    // of our nested lists
    highlightFollowsCurrentItem: false
    highlightRangeMode: ListView.NoHighlightRange

    highlight: Rectangle {
        id: highlightRectangle
        y:
            ! currentItem ?
            0 :

            selectedRoom ?
            currentItem.y + currentItem.account.height +
            currentItem.roomList.currentItem.y :

            currentItem.y

        width: mainPaneList.width
        height:
            ! currentItem ?
            0 :

            selectedRoom ?
            currentItem.roomList.currentItem.height :
            currentItem.account.height

        color:
            mainPane.small ?
            theme.controls.listView.smallPaneHighlight :
            theme.controls.listView.highlight

        Behavior on y { HNumberAnimation { id: yAnimation } }
        Behavior on height { HNumberAnimation {} }
        Behavior on color { HColorAnimation {} }

        Binding {
            target: mainPaneList
            property: "contentY"
            value: highlightRectangle.y + highlightRectangle.height / 2 -
                   mainPaneList.height / 2
            delayed: true
            when: centerToHighlight && yAnimation.running
        }

        Connections {
            target: mainPaneList
            enabled: centerToHighlight && yAnimation.running
            onContentYChanged: mainPaneList.returnToBounds()
        }
    }

    onMovingChanged: if (moving) centerToHighlight = false


    property bool detachedCurrentIndex: false
    property bool centerToHighlight: true

    readonly property HLoader selectedRoom:
        currentItem ? currentItem.roomList.currentItem : null

    readonly property bool hasActiveAccount:
        window.uiState.page === "Pages/Chat/Chat.qml" ||
        window.uiState.page === "Pages/AddChat/AddChat.qml" ||
        window.uiState.page === "Pages/AccountSettings/AccountSettings.qml"

    readonly property var activeAccountIndex:
        hasActiveAccount ?
        model.findIndex(window.uiState.pageProperties.userId) : null



    function previous() {
        centerToHighlight    = true
        detachedCurrentIndex = true

        if (! mainPane.filter) {
            _previous()
            return
        }

        let reachedStart = false
        do {
            if (currentIndex === count - 1 && reachedStart) break
            _previous()
            if (currentIndex === 0) reachedStart = true
        } while (! currentItem.roomList.currentItem)
    }

    function _previous() {
        const currentAccount = currentItem

        // Nothing is selected
        if (! currentAccount) {
            decrementCurrentIndex()
        }

        const roomList = currentAccount.roomList

        // An account is selected
        if (! roomList.currentItem) {
            decrementCurrentIndex()
            // Select the last room of the previous account that's now selected
            currentItem.roomList.decrementCurrentIndex()
            return
        }

        // A room is selected
        const selectedIsFirst = roomList.currentIndex === 0
        const noRooms         = roomList.count === 0

        if (currentAccount.collapsed || selectedIsFirst || noRooms) {
            // Have the account itself be selected
            roomList.currentIndex = -1  // XXX
        } else {
            roomList.decrementCurrentIndex()
        }
    }

    function next() {
        centerToHighlight    = true
        detachedCurrentIndex = true

        if (! mainPane.filter) {
            _next()
            return
        }

        let reachedEnd = false
        do {
            if (currentIndex === 0 && reachedEnd) break
            _next()
            if (currentIndex === count - 1) reachedEnd = true
        } while (! currentItem.roomList.currentItem)
    }

    function _next() {
        const currentAccount = currentItem

        // Nothing is selected
        if (! currentAccount) {
            incrementCurrentIndex()
            return
        }

        const roomList = currentAccount.roomList

        // An account is selected
        if (! roomList.currentItem) {
            if (currentAccount.collapsed || roomList.count === 0) {
                incrementCurrentIndex()
            } else {
                roomList.incrementCurrentIndex()
            }
            return
        }

        // A room is selected
        const selectedIsLast = roomList.currentIndex >= roomList.count - 1
        const noRooms        = roomList.count === 0

        if (currentAccount.collapsed || selectedIsLast || noRooms) {
            roomList.currentIndex = -1  // XXX
            mainPaneList.incrementCurrentIndex()
        } else {
            roomList.incrementCurrentIndex()
        }
    }

    function goToRoom(index) {
        if (! currentItem) next()
        if (! currentItem) return

        const room = currentItem.roomList.contentItem.children[index]
        print(index, room, room.item)
        if (room && room.item && room.item.activated) room.item.activated()
    }

    function requestActivate() {
        activateLimiter.restart()
    }

    function activate() {
        if (! currentItem) next()
        if (! currentItem) return

        selectedRoom ?
        currentItem.roomList.currentItem.item.activated() :
        currentItem.account.activated()

        detachedCurrentIndex = false
    }

    function accountSettings() {
        if (! currentItem) next()
        if (! currentItem) return
        currentItem.account.activated()

        detachedCurrentIndex = false
    }

    function addNewChat() {
        if (! currentItem) next()
        if (! currentItem) return
        currentItem.account.addChat.clicked()

        detachedCurrentIndex = false
    }

    function setCollapseAccount(collapse) {
        if (! currentItem) return
        currentItem.account.setCollapse(collapse)
    }

    function toggleCollapseAccount() {
        if (mainPane.filter) return
        if (! currentItem) next()

        currentItem.account.toggleCollapse()
    }


    Binding on currentIndex {
        value:
            hasActiveAccount ?
            (activeAccountIndex === null ? -1 : activeAccountIndex) : -1

        when: ! detachedCurrentIndex
    }

    HShortcut {
        sequences: window.settings.keys.addNewChat
        onActivated: addNewChat()
    }

    HShortcut {
        sequences: window.settings.keys.accountSettings
        onActivated: accountSettings()
    }

    HShortcut {
        sequences: window.settings.keys.toggleCollapseAccount
        onActivated: toggleCollapseAccount()
    }

    HShortcut {
        sequences: window.settings.keys.goToPreviousRoom
        onActivated: { previous(); requestActivate() }
    }

    HShortcut {
        sequences: window.settings.keys.goToNextRoom
        onActivated: { next(); requestActivate() }
    }

    Repeater {
        model: Object.keys(window.settings.keys.focusRoomAtIndex)

        Item {
            HShortcut {
                sequence: window.settings.keys.focusRoomAtIndex[modelData]
                onActivated: goToRoom(parseInt(modelData - 1, 10))
            }
        }
    }

    Timer {
        id: activateLimiter
        interval: 200
        onTriggered: activate()
    }

    Rectangle {
        anchors.fill: parent
        z: -100
        color: theme.mainPane.listView.background
    }
}
