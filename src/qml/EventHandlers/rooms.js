// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

"use strict"

Qt.include("../utils.js")

function typingTextFor(members, ourUserId) {
    let ourUsers = []
    let profiles = []
    let names    = []

    for (let i = 0;  i < accounts.count; i++) {
        ourUsers.push(accounts.get(i).userId)
    }

    for (let member of members) {
        if (! ourUsers.includes(member)) { profiles.push(users.find(member)) }
    }

    profiles.sort((left, right) => {
      if (left.displayName < right.displayName) { return -1 }
      if (left.displayName > right.displayName) { return +1 }
      return 0
    })

    for (let profile of profiles) {
        names.push(coloredNameHtml(profile.displayName, profile.userId))
    }

    if (names.length == 0) { return "" }
    if (names.length == 1) { return qsTr("%1 is typing...").arg(names[0]) }

    let text = qsTr("%1 and %2 are typing...")

    if (names.length == 2) { return text.arg(names[0]).arg(names[1]) }

    return text.arg(names.slice(0, -1).join(", ")).arg(names.slice(-1)[0])
}


function onRoomUpdated(
    userId, category, roomId, displayName, avatarUrl, topic,
    members, typingMembers, inviterId
) {
    roomCategories.upsert({userId, name: category}, {userId, name: category})

    function find(category) {
        let found = rooms.getIndices({userId, roomId, category}, 1)
        return found.length > 0 ? found[0] : null
    }

    let replace = null
    if (category == "Invites")    { replace = find("Rooms") || find("Left") }
    else if (category == "Rooms") { replace = find("Invites") || find("Left") }
    else if (category == "Left")  { replace = find("Invites") || find("Rooms")}

    let item = {
        loading:    false,
        typingText: typingTextFor(typingMembers, userId),

        userId, category, roomId, displayName, avatarUrl, topic, members,
        inviterId
    }

    if (replace === null) {
        rooms.upsert({userId, roomId, category}, item)
    } else {
        rooms.set(replace, item)
    }
}


function onRoomForgotten(userId, roomId) {
    rooms.popWhere({userId, roomId})
}


function onTimelineEventReceived(
    eventType, roomId, eventId, senderId, date, content, isLocalEcho,
    targetUserId
) {
    let item = {
        eventType: py.getattr(eventType, "__name__"),
        roomId, eventId, senderId, date, content, isLocalEcho, targetUserId
    }

    if (isLocalEcho) {
        timelines.append(item)
        return
    }

    // Replace first matching local echo
    let found = timelines.getIndices(
        {roomId, senderId, content, "isLocalEcho": true}, 1, 250
    )

    if (found.length > 0) {
        timelines.set(found[0], item)
    }
    // Multiple clients will emit duplicate events with the same eventId
    else if (item.eventType == "OlmEvent" || item.eventType == "MegolmEvent") {
        // Don't replace if an item with the same eventId is found in these
        // cases, because it would be the ecrypted version of the event.
        timelines.upsert({eventId}, item, false, 250)
    }
    else {
        timelines.upsert({eventId}, item, true, 250)
    }
}


var onTimelineMessageReceived = onTimelineEventReceived
