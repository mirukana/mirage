import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

HRectangle {
    property alias listView: eventList

    color: theme.chat.eventList.background

    HListView {
        id: eventList
        clip: true
        Component.onCompleted: shortcuts.flickTarget = eventList

        function canCombine(item, itemAfter) {
            if (! item || ! itemAfter) { return false }

            return Boolean(
                ! canTalkBreak(item, itemAfter) &&
                ! canDayBreak(item, itemAfter) &&
                item.sender_id === itemAfter.sender_id &&
                Utils.minutesBetween(item.date, itemAfter.date) <= 5
            )
        }

        function canTalkBreak(item, itemAfter) {
            if (! item || ! itemAfter) { return false }

            return Boolean(
                ! canDayBreak(item, itemAfter) &&
                Utils.minutesBetween(item.date, itemAfter.date) >= 20
            )
        }

        function canDayBreak(item, itemAfter) {
            if (! item || ! itemAfter || ! item.date || ! itemAfter.date) {
                return false
            }

            return Boolean(
                itemAfter.event_type == "RoomCreateEvent" ||
                item.date.getDate() != itemAfter.date.getDate()
            )
        }

        model: HListModel {
            keyField: "client_id"
            source:
                modelSources[["Event", chatPage.userId, chatPage.roomId]] || []
        }

        property bool ownEventsOnRight:
            width < theme.chat.eventList.ownEventsOnRightUnderWidth

        delegate: EventDelegate {}

        anchors.fill: parent
        anchors.leftMargin: theme.spacing
        anchors.rightMargin: theme.spacing

        topMargin: theme.spacing
        bottomMargin: theme.spacing
        verticalLayoutDirection: ListView.BottomToTop

        // Keep x scroll pages cached, to limit images having to be
        // reloaded from network.
        cacheBuffer: height * 4

        // Declaring this as "alias" provides the on... signal
        property real yPos: visibleArea.yPosition
        property bool canLoad: true
        onYPosChanged: Qt.callLater(loadPastEvents)

        function loadPastEvents() {
            if (chatPage.invited_id || ! canLoad || yPos > 0.1) { return }
            eventList.canLoad = false
            py.callClientCoro(
                chatPage.userId, "load_past_events", [chatPage.roomId],
                moreToLoad => { eventList.canLoad = moreToLoad }
            )
        }
    }

    HNoticePage {
        text: qsTr("Nothing here yet...")

        visible: eventList.model.count < 1
        anchors.fill: parent
    }
}
