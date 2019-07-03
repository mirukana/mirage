function onRoomUpdated(user_id, category, room_id, display_name, avatar_url,
                       topic, last_event_date, inviter, left_event) {

    models.roomCategories.upsert({"userId": user_id, "name": category}, {
        "userId": user_id,
        "name":   category
    })

    var rooms = models.rooms

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
        "lastEventDate": last_event_date,
        "inviter":       inviter,
        "leftEvent":     left_event
    })
    //print("room up", rooms.toJson())
}


function onRoomDeleted(user_id, category, room_id) {
    var roles = {"userId": user_id, "roomId": room_id, "category": category}
    models.rooms.popWhere(roles, 1)
}


function onRoomMemberUpdated(room_id, user_id, typing) {
}


function onRoomMemberDeleted(room_id, user_id) {
}


function onTimelineEventReceived(
    event_type, room_id, event_id, sender_id, date, content,
    content_type, is_local_echo, show_name_line, translatable, target_user_id
) {
    models.timelines.upsert({"eventId": event_id}, {
        "eventType":    py.getattr(event_type, "__name__"),
        "roomId":       room_id,
        "eventId":      event_id,
        "senderId":     sender_id,
        "date":         date,
        "content":      content,
        "contentType":  content,
        "isLocalEcho":  is_local_echo,
        "showNameLine": show_name_line,
        "translatable": translatable,
        "targetUserId": target_user_id
    }, true, 1000)
}

var onTimelineMessageReceived = onTimelineEventReceived
