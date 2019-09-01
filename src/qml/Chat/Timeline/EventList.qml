import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

Rectangle {
    property alias selectableLabelContainer: selectableLabelContainer
    property alias eventList: eventList

    color: theme.chat.eventList.background

    HSelectableLabelContainer {
        id: selectableLabelContainer
        anchors.fill: parent
        reversed: eventList.verticalLayoutDirection == ListView.BottomToTop

        onDragPositionChanged: {
            let left = dragPoint.pressedButtons & Qt.LeftButton
            let vel  = dragPoint.velocity.y

            let boost = 20 * (
                dragPosition.y < 50 ?
                -dragPosition.y : -(height - dragPosition.y)
            )

            dragFlicker.speed =
                dragPosition.x == 0 && dragPosition.y == 0  ? 0 :
                left && vel && dragPosition.y < 50          ? 1000 + boost:
                left && vel && dragPosition.y > height - 50 ? -1000 + -boost :
                0
        }


        Timer {
            id: dragFlicker
            interval: 100
            running: speed != 0
            repeat: true

            onTriggered: {
                if (eventList.verticalOvershoot != 0) return
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

        HListView {
            id: eventList
            clip: true
            enableFlicking: false

            anchors.fill: parent
            anchors.leftMargin: theme.spacing
            anchors.rightMargin: theme.spacing

            topMargin: theme.spacing
            bottomMargin: theme.spacing
            verticalLayoutDirection: ListView.BottomToTop

            // Keep x scroll pages cached, to limit images having to be
            // reloaded from network.
            cacheBuffer: height * 4

            onYPosChanged:
                if (canLoad && yPos < 0.1) Qt.callLater(loadPastEvents)

            // When an invited room becomes joined, we should now be able to
            // fetch past events.
            onInviterChanged: canLoad = true

            Component.onCompleted: shortcuts.flickTarget = eventList


            property string inviter: chatPage.roomInfo.inviter || ""
            property real yPos: visibleArea.yPosition
            property bool canLoad: true

            property bool ownEventsOnRight:
                width < theme.chat.eventList.ownEventsOnRightUnderWidth


            function canCombine(item, itemAfter) {
                if (! item || ! itemAfter) return false

                return Boolean(
                    ! canTalkBreak(item, itemAfter) &&
                    ! canDayBreak(item, itemAfter) &&
                    item.sender_id === itemAfter.sender_id &&
                    Utils.minutesBetween(item.date, itemAfter.date) <= 5
                )
            }

            function canTalkBreak(item, itemAfter) {
                if (! item || ! itemAfter) return false

                return Boolean(
                    ! canDayBreak(item, itemAfter) &&
                    Utils.minutesBetween(item.date, itemAfter.date) >= 20
                )
            }

            function canDayBreak(item, itemAfter) {
                if (itemAfter && itemAfter.event_type == "RoomCreateEvent")
                    return true

                if (! item || ! itemAfter || ! item.date || ! itemAfter.date)
                    return false

                return item.date.getDate() != itemAfter.date.getDate()
            }

            function loadPastEvents() {
                // try/catch blocks to hide pyotherside error when the
                // component is destroyed but func is still running

                try {
                    eventList.canLoad = false

                    py.callClientCoro(
                        chatPage.userId, "load_past_events", [chatPage.roomId],
                        moreToLoad => {
                            try {
                                eventList.canLoad = moreToLoad
                            } catch (err) {
                                return
                            }
                        }
                    )
                } catch (err) {
                    return
                }
            }


            model: HListModel {
                keyField: "client_id"
                source: modelSources[[
                    "Event", chatPage.userId, chatPage.roomId
                ]] || []
            }

            delegate: EventDelegate {}
        }
    }

    HNoticePage {
        text: qsTr("No messages visible yet.")

        visible: eventList.model.count < 1
        anchors.fill: parent
    }
}
