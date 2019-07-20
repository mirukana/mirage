// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

Column {
    id: eventDelegate

    // Remember timeline goes from newest message at index 0 to oldest
    property var previousItem: eventList.model.get(model.index + 1)
    property var nextItem: eventList.model.get(model.index - 1)

    property int modelIndex: model.index
    onModelIndexChanged: {
        previousItem = eventList.model.get(model.index + 1)
        nextItem     = eventList.model.get(model.index - 1)
    }

    property var senderInfo: senderInfo = users.find(model.senderId)

    property bool isOwn: chatPage.userId === model.senderId
    property bool onRight: eventList.ownEventsOnRight && isOwn
    property bool combine: eventList.canCombine(previousItem, model)
    property bool talkBreak: eventList.canTalkBreak(previousItem, model)
    property bool dayBreak: eventList.canDayBreak(previousItem, model)

    readonly property bool smallAvatar:
        eventList.canCombine(model, nextItem) &&
        (model.eventType == "RoomMessageEmote" ||
         ! model.eventType.startsWith("RoomMessage"))

    readonly property bool collapseAvatar: combine
    readonly property bool hideAvatar: onRight

    readonly property bool hideNameLine:
        model.eventType == "RoomMessageEmote" ||
        ! model.eventType.startsWith("RoomMessage") ||
        onRight ||
        combine

    width: eventList.width

    topPadding:
        model.eventType == "RoomCreateEvent" ? 0 :
        dayBreak  ? theme.spacing * 4 :
        talkBreak ? theme.spacing * 6 :
        combine   ? theme.spacing / 2 :
        theme.spacing * 2

    Daybreak {
        visible: dayBreak
        width: eventDelegate.width
    }

    EventContent {
        x: onRight ? parent.width - width : 0
        Behavior on x { HNumberAnimation {} }
    }
}
