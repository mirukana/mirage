// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import "../../.."
import "../../../Base"

Rectangle {
    color: theme.chat.eventList.background


    property alias eventList: eventList


    HShortcut {
        sequence: "Escape"
        onActivated: eventList.checkedDelegates = {}
    }

    HListView {
        id: eventList
        clip: true

        anchors.fill: parent
        anchors.leftMargin: theme.spacing
        anchors.rightMargin: theme.spacing

        topMargin: theme.spacing
        bottomMargin: theme.spacing
        verticalLayoutDirection: ListView.BottomToTop

        // Keep x scroll pages cached, to limit images having to be
        // reloaded from network.
        cacheBuffer: Screen.desktopAvailableHeight * 2

        model: ModelStore.get(chat.userId, chat.roomId, "events")
        delegate: EventDelegate {}

        // Since the list is BottomToTop, this is actually a header
        footer: Item {
            width: eventList.width
            height: (button.height + theme.spacing * 2) * opacity
            opacity: eventList.loading ? 1 : 0
            visible: opacity > 0

            Behavior on opacity { HNumberAnimation {} }

            HButton {
                id: button
                width: Math.min(parent.width, implicitWidth)
                anchors.centerIn: parent

                loading: true
                text: qsTr("Loading previous messages...")
                enableRadius: true
                iconItem.small: true
            }
        }

        onYPosChanged:
            if (canLoad && yPos < 0.1) Qt.callLater(loadPastEvents)

        // When an invited room becomes joined, we should now be able to
        // fetch past events.
        onInviterChanged: canLoad = true

        Component.onCompleted: shortcuts.flickTarget = eventList


        property string inviter: chat.roomInfo.inviter || ""
        property real yPos: visibleArea.yPosition
        property bool canLoad: true
        property bool loading: false

        property bool ownEventsOnRight:
            width < theme.chat.eventList.ownEventsOnRightUnderWidth

        property string delegateWithSelectedText: ""


        function canCombine(item, itemAfter) {
            if (! item || ! itemAfter) return false

            return Boolean(
                ! canTalkBreak(item, itemAfter) &&
                ! canDayBreak(item, itemAfter) &&
                item.sender_id === itemAfter.sender_id &&
                utils.minutesBetween(item.date, itemAfter.date) <= 5
            )
        }

        function canTalkBreak(item, itemAfter) {
            if (! item || ! itemAfter) return false

            return Boolean(
                ! canDayBreak(item, itemAfter) &&
                utils.minutesBetween(item.date, itemAfter.date) >= 20
            )
        }

        function canDayBreak(item, itemAfter) {
            if (itemAfter && itemAfter.event_type === "RoomCreateEvent")
                return true

            if (! item || ! itemAfter || ! item.date || ! itemAfter.date)
                return false

            return item.date.getDate() !== itemAfter.date.getDate()
        }

        function loadPastEvents() {
            // try/catch blocks to hide pyotherside error when the
            // component is destroyed but func is still running

            try {
                eventList.canLoad = false
                eventList.loading = true

                py.callClientCoro(
                    chat.userId,
                    "load_past_events",
                    [chat.roomId],
                    moreToLoad => {
                        try {
                            eventList.canLoad = moreToLoad

                            // Call yPosChanged() to run this func again
                            // if the loaded messages aren't enough to fill
                            // the screen.
                            if (moreToLoad) yPosChanged()

                            eventList.loading = false
                        } catch (err) {
                            return
                        }
                    }
                )
            } catch (err) {
                return
            }
        }
    }


    HNoticePage {
        text: qsTr("No messages to show yet")

        visible: eventList.model.count < 1
        anchors.fill: parent
    }

    DragHandler {
        target: null
        onActiveChanged: if (! active) dragFlicker.speed = 0
        onCentroidChanged: {
            const left  = centroid.pressedButtons & Qt.LeftButton
            const vel   = centroid.velocity.y
            const pos   = centroid.position.y
            const dist  = Math.min(eventList.height / 4, 50)
            const boost = 20 * (pos < dist ?  -pos : -(height - pos))

            dragFlicker.speed =
                left && vel && pos < dist          ? 1000 + boost :
                left && vel && pos > height - dist ? -1000 + -boost :
                0
        }
    }

    Timer {
        id: dragFlicker
        interval: 100
        running: speed !== 0
        repeat: true

        onTriggered: {
            if (eventList.verticalOvershoot !== 0) return
            if (speed < 0 && eventList.atYEnd) return
            if (eventList.atYBeggining) {
                if (bouncedStart) { return } else { bouncedStart = true }
            }

            eventList.flick(0, speed * acceleration)
            acceleration = Math.min(8, acceleration * 1.05)
        }
        onRunningChanged: if (! running) {
            acceleration = 1.0
            bouncedStart = false
            eventList.cancelFlick()
            eventList.returnToBounds()
        }

        property real speed: 0.0
        property real acceleration: 1.0
        property bool bouncedStart: false
    }
}
