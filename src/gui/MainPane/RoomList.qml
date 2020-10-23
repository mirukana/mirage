// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Qt.labs.qmlmodels 1.0
import ".."
import "../Base"

HListView {
    id: roomList

    property string filter: ""

    property bool keepListCentered: true

    readonly property bool currentShouldBeAccount:
        window.uiState.page === "Pages/AccountSettings/AccountSettings.qml" ||
        window.uiState.page === "Pages/AddChat/AddChat.qml"

    readonly property bool currentShouldBeRoom:
        window.uiState.page === "Pages/Chat/Chat.qml"

    readonly property string wantedUserId: (
        window.uiState.pageProperties.userRoomId ||
        [window.uiState.pageProperties.userId, ""]
    )[0] || ""

    readonly property string wantedRoomId: (
        window.uiState.pageProperties.userRoomId ||
        ["", window.uiState.pageProperties.roomId]
    )[1] || ""

    readonly property var accountIndice: {
        const accounts = {}

        for (let i = 0; i < model.count; i++) {
            if (model.get(i).type === "Account")
                accounts[model.get(i).id] = i
        }

        return accounts
    }

    function goToAccount(userId) {
        accountIndice[userId] + 1 <= model.count -1 &&
        model.get(accountIndice[userId] + 1).type === "Room" ?
        currentIndex = accountIndice[userId] + 1 :
        currentIndex = accountIndice[userId]

        showItemLimiter.restart()
    }

    function goToAccountNumber(num) {
        const index = Object.entries(accountIndice).sort()[num][1]

        model.get(index + 1).type === "Room" ?
        currentIndex = index + 1 :
        currentIndex = index

        showItemLimiter.restart()
    }

    function showItemAtIndex(index=currentIndex, fromClick=false) {
        if (index === -1) index = 0
        index = Math.min(index, model.count - 1)

        const item = model.get(index)

        item.type === "Account" ?
        pageLoader.show(
            "Pages/AccountSettings/AccountSettings.qml", { "userId": item.id },
        ) :
        pageLoader.showRoom(item.for_account, item.id)

        if (fromClick && ! window.settings.centerRoomListOnClick)
            keepListCentered = false

        currentIndex = index

        if (fromClick && ! window.settings.centerRoomListOnClick)
            keepListCentered = true
    }

    function showAccountRoomAtIndex(index) {
        const item = model.get(currentIndex === -1 ?  0 : currentIndex)

        const currentUserId =
            item.type === "Account" ? item.id : item.for_account

        showItemAtIndex(accountIndice[currentUserId] + 1 + index)
    }

    function cycleUnreadRooms(forward=true, highlights=false) {
        const prop       = highlights ? "highlights" : "unreads"
        const local_prop = highlights ? "local_highlights" : "local_unreads"
        const start      = currentIndex === -1 ? 0 : currentIndex
        let index        = start

        while (true) {
            index += forward ? 1 : -1

            if (index < 0) index = model.count - 1
            if (index > model.count - 1) index = 0

            if (index === start && highlights)
                return cycleUnreadRooms(forward, false)
            else if (index === start)
                return false

            const item = model.get(index)

            if (item.type === "Room" && (item[prop] || item[local_prop])) {
                currentIndex = index
                return true
            }
        }
    }

    function startCorrectItemSearch() {
        correctTimer.start()
    }

    function setCorrectCurrentItem() {
        if (! currentShouldBeRoom && ! currentShouldBeAccount) {
            currentIndex = -1
            return null
        }

        for (let i = 0; i < model.count; i++) {
            const item = model.get(i)

            if ((
                currentShouldBeRoom &&
                item.type === "Room" &&
                item.id === wantedRoomId &&
                item.for_account === wantedUserId
            ) || (
                currentShouldBeAccount &&
                item.type === "Account" &&
                item.id === wantedUserId
            )) {
                currentIndex = i
                return true
            }
        }

        return false
    }


    highlightRangeMode:
        keepListCentered ? ListView.ApplyRange : ListView.NoHighlightRange

    model: ModelStore.get("all_rooms")

    delegate: DelegateChooser {
        role: "type"

        DelegateChoice {
            roleValue: "Account"
            AccountDelegate {
                width: roomList.width
                leftPadding: theme.spacing
                rightPadding: 0  // the right buttons have padding

                filterActive: Boolean(filter)
                enableKeybinds: Boolean(
                    roomList.model.get(currentIndex) && (
                        roomList.model.get(currentIndex).for_account ||
                        roomList.model.get(currentIndex).id
                    ) === model.id
                )

                totalMessageIndicator.visible: false

                onLeftClicked: showItemAtIndex(model.index, true)
                onCollapsedChanged:
                    if (wantedUserId === model.id) startCorrectItemSearch()

                onWentToAccountPage: roomList.currentIndex = model.index
            }
        }

        DelegateChoice {
            roleValue: "Room"
            RoomDelegate {
                width: roomList.width
                onLeftClicked: showItemAtIndex(model.index, true)
            }
        }
    }

    onFilterChanged: {
        py.callCoro("set_string_filter", ["all_rooms", filter], () => {
            if (filter) {
                currentIndex = 1  // highlight the first matching room
                return
            }

            const item = model.get(currentIndex)

            if (
                ! filter &&
                item && (
                    currentIndex === 1 || // required, related to the if above
                    (
                        currentShouldBeAccount &&
                        wantedUserId !== item.id
                    ) || (
                        currentShouldBeRoom && (
                            wantedUserId !== item.for_account ||
                            wantedRoomId !== item.id
                        )
                     )
                )
            )
                startCorrectItemSearch()
        })
    }

    Connections {
        target: pageLoader
        onPreviousShown: (componentUrl, properties)  => {
            if (setCorrectCurrentItem() === false) startCorrectItemSearch()
        }
    }

    Timer {
        // On startup, the account/room takes an unknown amount of time to
        // arrive in the model, try to find it until then.
        id: correctTimer
        interval: 200
        running: currentIndex === -1
        repeat: true
        triggeredOnStart: true
        onTriggered: setCorrectCurrentItem()
        onRunningChanged: if (running && currentIndex !== -1) currentIndex = -1
    }

    Timer {
        id: showItemLimiter
        interval: 100
        onTriggered: showItemAtIndex()
    }

    HShortcut {
        sequences: window.settings.keys.goToPreviousRoom
        onActivated: { decrementCurrentIndex(); showItemLimiter.restart() }
    }

    HShortcut {
        sequences: window.settings.keys.goToNextRoom
        onActivated: { incrementCurrentIndex(); showItemLimiter.restart() }
    }

    HShortcut {
        sequences: window.settings.keys.goToPreviousUnreadRoom
        onActivated: { cycleUnreadRooms(false) && showItemLimiter.restart() }
    }

    HShortcut {
        sequences: window.settings.keys.goToNextUnreadRoom
        onActivated: { cycleUnreadRooms(true) && showItemLimiter.restart() }
    }

    HShortcut {
        sequences: window.settings.keys.goToPreviousMentionedRoom
        onActivated: cycleUnreadRooms(false, true) && showItemLimiter.restart()
    }

    HShortcut {
        sequences: window.settings.keys.goToNextMentionedRoom
        onActivated: cycleUnreadRooms(true, true) && showItemLimiter.restart()
    }

    Repeater {
        model: Object.keys(window.settings.keys.focusAccountAtIndex)

        Item {
            HShortcut {
                sequence: window.settings.keys.focusAccountAtIndex[modelData]
                onActivated: goToAccountNumber(parseInt(modelData - 1, 10))
            }
        }
    }

    Repeater {
        model: Object.keys(window.settings.keys.focusRoomAtIndex)

        Item {
            HShortcut {
                sequence: window.settings.keys.focusRoomAtIndex[modelData]
                onActivated:
                    showAccountRoomAtIndex(parseInt(modelData - 1, 10))
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        z: -100
        color: theme.mainPane.listView.background
    }
}
