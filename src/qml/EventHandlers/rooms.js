function clientId(user_id, category, room_id) {
    return user_id + " " + room_id + " " + category
}


function onRoomUpdated(user_id, category, room_id, display_name, avatar_url,
                       topic, last_event_date, inviter, left_event) {

    var client_id = clientId(user_id, category, room_id)
    var rooms     = models.rooms

    if (category == "Invites") {
        rooms.popWhere("clientId", clientId(user_id, "Rooms", room_id))
        rooms.popWhere("clientId", clientId(user_id, "Left", room_id))
    }
    else if (category == "Rooms") {
        rooms.popWhere("clientId", clientId(user_id, "Invites", room_id))
        rooms.popWhere("clientId", clientId(user_id, "Left", room_id))
    }
    else if (category == "Left") {
        var old_room  =
            rooms.popWhere("clientId", clientId(user_id, "Rooms", room_id)) ||
            rooms.popWhere("clientId", clientId(user_id, "Invites", room_id))

        if (old_room) {
            display_name = old_room.displayName
            avatar_url   = old_room.avatarUrl
            topic        = old_room.topic
            inviter      = old_room.topic
        }
    }

    rooms.upsert("clientId", client_id , {
        "clientId":      client_id,
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
    var client_id = clientId(user_id, category, room_id)
    return models.rooms.popWhere("clientId", client_id, 1)
}


function onRoomMemberUpdated(room_id, user_id, typing) {
}


function onRoomMemberDeleted(room_id, user_id) {
}
