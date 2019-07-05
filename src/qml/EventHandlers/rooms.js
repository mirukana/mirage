function onRoomUpdated(user_id, category, room_id, display_name, avatar_url,
                       topic, inviter, left_event) {

    roomCategories.upsert({"userId": user_id, "name": category}, {
        "userId": user_id,
        "name":   category
    })

    function roles(for_category) {
        return {"userId": user_id, "roomId": room_id, "category": for_category}
    }

    if (category == "Invites") {
        rooms.popWhere(roles("Rooms"), 1)
        rooms.popWhere(roles("Left"), 1)
    }
    else if (category == "Rooms") {
        rooms.popWhere(roles("Invites"), 1)
        rooms.popWhere(roles("Left"), 1)
    }
    else if (category == "Left") {
        var old_room  = rooms.popWhere(roles("Invites"), 1)[0] ||
                        rooms.popWhere(roles("Rooms"), 1)[0]

        if (old_room) {
            display_name = old_room.displayName
            avatar_url   = old_room.avatarUrl
            topic        = old_room.topic
            inviter      = old_room.topic
        }
    }

    rooms.upsert(roles(category), {
        "userId":        user_id,
        "category":      category,
        "roomId":        room_id,
        "displayName":   display_name,
        "avatarUrl":     avatar_url,
        "topic":         topic,
        "inviter":       inviter,
        "leftEvent":     left_event
    })
}


function onRoomDeleted(user_id, category, room_id) {
    var roles = {"userId": user_id, "roomId": room_id, "category": category}
    rooms.popWhere(roles, 1)
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
        "targetUserId": target_user_id,
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
