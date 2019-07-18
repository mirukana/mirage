// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

Column {
    id: roomEventDelegate

    function minsBetween(date1, date2) {
        return Math.round((((date2 - date1) % 86400000) % 3600000) / 60000)
    }

    function getPreviousItem(nth=1) {
        // Remember, index 0 = newest bottomest message
        return eventList.model.count - 1 > model.index + nth ?
                eventList.model.get(model.index + nth) : null
    }

    property var previousItem: getPreviousItem()
    signal reloadPreviousItem()
    onReloadPreviousItem: previousItem = getPreviousItem()

    property var senderInfo: null
    Component.onCompleted: senderInfo = users.find(model.senderId)

    readonly property bool isOwn: chatPage.userId === model.senderId

    readonly property bool isFirstEvent: model.eventType == "RoomCreateEvent"

    // Item roles may not be loaded yet, reason for all these checks
    readonly property bool combine: Boolean(
        model.date &&
        previousItem && previousItem.eventType && previousItem.date &&
        Utils.eventIsMessage(previousItem) == Utils.eventIsMessage(model) &&
        ! talkBreak &&
        ! dayBreak &&
        previousItem.senderId === model.senderId &&
        minsBetween(previousItem.date, model.date) <= 5
    )

    readonly property bool dayBreak: Boolean(
        isFirstEvent ||
        model.date && previousItem && previousItem.date &&
        model.date.getDate() != previousItem.date.getDate()
    )

    readonly property bool talkBreak: Boolean(
        model.date && previousItem && previousItem.date &&
        ! dayBreak &&
        minsBetween(previousItem.date, model.date) >= 20
    )


    readonly property int horizontalPadding: theme.spacing
    readonly property int verticalPadding: theme.spacing / 2

    ListView.onAdd: {
        let nextDelegate = eventList.contentItem.children[index]
        if (nextDelegate) { nextDelegate.reloadPreviousItem() }
    }

    width: parent.width

    topPadding:
        isFirstEvent ? 0 :
        dayBreak ? theme.spacing * 4 :
        talkBreak ? theme.spacing * 6 :
        combine ? theme.spacing / 2 :
        theme.spacing * 2

    Loader {
        source: dayBreak ? "Daybreak.qml" : ""
        width: roomEventDelegate.width
    }

    EventContent {
        anchors.right: isOwn ? parent.right : undefined
    }
}
