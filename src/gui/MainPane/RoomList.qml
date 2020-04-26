// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."
import "../Base"

HListView {
    id: roomList
    model: ModelStore.get(accountModel.id, "rooms")

    delegate: Room {
        width: roomList.width
        userId: accountModel.id
        onActivated: showRoom(model.index)
    }


    property var accountModel
    property var roomPane
    property bool isCurrent: false


    function showRoom(index=currentIndex) {
        pageLoader.showRoom(accountModel.id, model.get(index).id)
        currentIndex = index
    }


    Timer {
        id: showRoomLimiter
        interval: 200
        onTriggered: showRoom()
    }

    HShortcut {
        enabled: isCurrent
        sequences: window.settings.keys.goToPreviousRoom
        onActivated: { decrementCurrentIndex(); showRoomLimiter.restart() }
    }

    HShortcut {
        enabled: isCurrent
        sequences: window.settings.keys.goToNextRoom
        onActivated: { incrementCurrentIndex(); showRoomLimiter.restart() }
    }

    Repeater {
        model: Object.keys(window.settings.keys.focusRoomAtIndex)

        Item {
            HShortcut {
                enabled: isCurrent
                sequence: window.settings.keys.focusRoomAtIndex[modelData]
                onActivated: showRoom(parseInt(modelData - 1, 10))
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: {
            const goingDown = wheel.angleDelta.y < 0

            if (! goingDown && roomList.atYBeginning)
                roomPane.decrementCurrentIndex()
            else if (goingDown && roomList.atYEnd)
                roomPane.incrementCurrentIndex()
            else
                wheel.accepted = false
        }
    }
}
