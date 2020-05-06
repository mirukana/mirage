// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQml.Models 2.12
import ".."
import "../Base"

HListView {
    id: roomList
    add: null  // See the XXX comment in HListView.qml

    model: HStringFilterModel {
        id: filterModel
        sourceModel: ModelStore.get("every_room")
        field: "display_name"

        delegate: Room {
            id: room
            width: roomList.width
            onActivated: showRoomAtIndex(DelegateModel.filteredIndex)
            ListView.onAdd: ParallelAnimation {
                HNumberAnimation {
                    target: room; property: "opacity"; from: 0; to: 1;
                }
                HNumberAnimation {
                    target: room; property: "scale"; from: 0; to: 1;
                }
            }
        }
    }

    section.property: "for_account"
    section.labelPositioning:
        ViewSection.InlineLabels | ViewSection.CurrentLabelAtStart

    section.delegate: Account {
        width: roomList.width
        accountModel: ModelStore.get("accounts").find(section)
    }


    property alias filter: filterModel.filter
    readonly property var sectionIndice: {
        const sections    = {}
        let currentUserId = null

        for (let i = 0; i < model.filtered.count; i++) {
            const userId = model.filtered.get(i).model.for_account

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
        index = Math.min(index, model.filtered.count - 1)

        const room = model.filtered.get(index).model
        pageLoader.showRoom(room.for_account, room.id)
        currentIndex = index
    }

    function showAccountRoomAtIndex(index) {
        const currentUserId = model.filtered.get(
            currentIndex === -1 ?  0 : currentIndex
        ).model.for_account

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
