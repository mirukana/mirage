Qt.include("../utils.js")


function typingTextFor(members, our_user_id) {
    var profiles = []
    var names    = []

    for (var i = 0; i < members.length; i++) {
        if (members[i] != our_user_id) {
            profiles.push(users.find(members[i]))
        }
    }

    profiles.sort(function(left, right) {
      if (left.displayName < right.displayName) { return -1 }
      if (left.displayName > right.displayName) { return +1 }
      return 0
    })

    for (var i = 0; i < profiles.length; i++) {
        var profile = profiles[i]
        names.push(coloredNameHtml(profile.displayName, profile.userId))
    }

    if (names.length == 0) { return "" }
    if (names.length == 1) { return qsTr("%1 is typing...").arg(names[0]) }

    var text = qsTr("%1 and %2 are typing...")

    if (names.length == 2) { return text.arg(names[0]).arg(names[1]) }

    return text.arg(names.slice(0, -1).join(", ")).arg(names.slice(-1)[0])
}


function onRoomUpdated(
    user_id, category, room_id, display_name, avatar_url, topic,
    members, typing_members, inviter_id
) {
    roomCategories.upsert({"userId": user_id, "name": category}, {
        "userId": user_id,
        "name":   category
    })

    function find(for_category) {
        var found = rooms.getIndices(
            {"userId": user_id, "roomId": room_id, "category": for_category}, 1
        )
        return found.length > 0 ? found[0] : null
    }

    var replace = null
    if (category == "Invites")    { replace = find("Rooms") || find("Left") }
    else if (category == "Rooms") { replace = find("Invites") || find("Left") }
    else if (category == "Left")  { replace = find("Invites") || find("Rooms")}

    var item = {
        "userId":      user_id,
        "category":    category,
        "roomId":      room_id,
        "displayName": display_name,
        "avatarUrl":   avatar_url,
        "topic":       topic,
        "members":     members,
        "typingText":  typingTextFor(typing_members, user_id),
        "inviterId":   inviter_id
    }

    if (replace === null) {
        rooms.upsert(
            {"userId": user_id, "roomId": room_id, "category": category},
            item
        )
    } else {
        rooms.set(replace, item)
    }

}


function onRoomForgotten(user_id, room_id) {
    rooms.popWhere({"userId": user_id, "roomId": room_id})
}


function onRoomMemberUpdated(room_id, user_id, typing) {
}


function onRoomMemberDeleted(room_id, user_id) {
}


function onTimelineEventReceived(
    event_type, room_id, event_id, sender_id, date, content,
    content_type, is_local_echo, show_name_line, translatable, target_user_id
) {
    var item = {
        "eventType":    py.getattr(event_type, "__name__"),
        "roomId":       room_id,
        "eventId":      event_id,
        "senderId":     sender_id,
        "date":         date,
        "content":      content,
        "contentType":  content_type,
        "isLocalEcho":  is_local_echo,
        "showNameLine": show_name_line,
        "translatable": translatable,
        "tarfindId": target_user_id,
    }

    if (is_local_echo) {
        timelines.append(item)
        return
    }

    // Replace first matching local echo
    var found = timelines.getIndices({
        "roomId":       room_id,
        "senderId":     sender_id,
        "content":      content,
        "isLocalEcho":  true
    }, 1, 250)

    if (found.length > 0) {
        timelines.set(found[0], item)
    } else {
        // Multiple clients will emit duplicate events with the same eventId
        timelines.upsert({"eventId": event_id}, item, true, 250)
    }
}


var onTimelineMessageReceived = onTimelineEventReceived


function onTypingNoticeEvent(room_id, members) {
}
