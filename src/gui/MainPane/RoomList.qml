// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQml.Models 2.12
import ".."
import "../Base"

HListView {
    id: roomList
    model: ModelStore.get("all_rooms")

    delegate: Room {
        id: room
        width: roomList.width
        onActivated: showRoomAtIndex(model.index)
    }

    section.property: "for_account"
    section.labelPositioning:
        ViewSection.InlineLabels | ViewSection.CurrentLabelAtStart

    section.delegate: Account {
        width: roomList.width
        accountModel: ModelStore.get("accounts").find(section)
    }

    onFilterChanged: py.callCoro("set_substring_filter", ["all_rooms", filter])


    property string filter: ""
    readonly property var sectionIndice: {
        const sections    = {}
        let currentUserId = null

        for (let i = 0; i < model.count; i++) {
            const userId = model.get(i).for_account

            if (userId !== currentUserId) {
                sections[userId] = i
                currentUserId    = userId
            }
        }

        return sections
    }


    function goToAccount(userId) {
        currentIndex = sectionIndice[userId]
    }

    function goToAccountNumber(num) {
        currentIndex = Object.values(sectionIndice).sort()[num]
    }

    function showRoomAtIndex(index=currentIndex) {
        if (index === -1) index = 0
        index = Math.min(index, model.count - 1)

        const room = model.get(index)
        pageLoader.showRoom(room.for_account, room.id)
        currentIndex = index
    }

    function showAccountRoomAtIndex(index) {
        const currentUserId = model.get(
            currentIndex === -1 ?  0 : currentIndex
        ).for_account

        showRoomAtIndex(sectionIndice[currentUserId] + index)
    }


    Timer {
        id: showRoomLimiter
        interval: 200
        onTriggered: showRoomAtIndex()
    }

    HShortcut {
        sequences: window.settings.keys.goToPreviousRoom
        onActivated: { decrementCurrentIndex(); showRoomLimiter.restart() }
    }

    HShortcut {
        sequences: window.settings.keys.goToNextRoom
        onActivated: { incrementCurrentIndex(); showRoomLimiter.restart() }
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
        color: theme.accountView.roomList.background
    }
}
