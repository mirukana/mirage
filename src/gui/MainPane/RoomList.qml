// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."
import "../Base"

HListView {
    id: roomList
    model: ModelStore.get("every_room")

    section.property: "for_account"
    section.labelPositioning:
        ViewSection.InlineLabels | ViewSection.CurrentLabelAtStart
    section.delegate: Account {
        accountModel: ModelStore.get("accounts").find(section)
        width: roomList.width
    }

    delegate: Room {
        width: roomList.width
        onActivated: showRoomAtIndex(model.index)
    }


    readonly property var sectionIndice: {
        const sections = {}
        const accounts = ModelStore.get("accounts")
        let total      = 0

        for (let i = 0; i < accounts.count; i++) {
            const userId = accounts.get(i).id
            sections[userId] = total
            total += ModelStore.get(userId, "rooms").count
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
        const userId =
            model.get(currentIndex === -1 ? 0 : currentIndex).for_account

        const rooms = ModelStore.get(userId, "rooms")
        if (! rooms.count) return

        const room = rooms.get(utils.numberWrapAt(index, rooms.count))
        showRoomAtIndex(model.findIndex(room.id))
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
