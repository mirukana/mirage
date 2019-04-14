function get_event_text(type, dict) {
    switch (type) {
        case "RoomCreateEvent":
            return (dict.federate ? "allowed" : "blocked") +
                   " users on other matrix servers " +
                   (dict.federate ? "to join" : "from joining") +
                   " this room."
            break

        case "RoomGuestAccessEvent":
            return (dict.guest_access === "can_join" ? "allowed " : "forbad") +
                   "guests to join the room."
            break

        case "RoomJoinRulesEvent":
            return "made the room " +
                   (dict.join_rule === "public." ? "public" : "invite only.")
            break

        case "RoomHistoryVisibilityEvent":
            return get_history_visibility_event_text(dict)
            break

        case "PowerLevelsEvent":
            return "changed the room's permissions."

        case "RoomMemberEvent":
            return get_member_event_text(dict)
            break

        case "RoomAliasEvent":
            return "set the room's main address to " +
                   dict.canonical_alias + "."
            break

        case "RoomNameEvent":
            return "changed the room's name to \"" + dict.name + "\"."
            break

        case "RoomTopicEvent":
            return "changed the room's topic to \"" + dict.topic + "\"."
            break

        case "RoomEncryptionEvent":
            return "turned on encryption for this room."
            break

        case "OlmEvent":
        case "MegolmEvent":
            return "hasn't sent your device the keys to decrypt this message."

        default:
            console.log(type + "\n" + JSON.stringify(dict, null, 4) + "\n")
            return "did something this client does not understand."

        //case "CallEvent":  TODO
    }
}


function get_history_visibility_event_text(dict) {
    switch (dict.history_visibility) {
        case "shared":
            var end = "all room members."
            break

        case "world_readable":
            var end = "any member or outsider."
            break

        case "joined":
            var end = "all room members since they joined."
            break

        case "invited":
            var end = "all room members since they were invited."
            break
        }

    return "made future history visible to " + end
}


function get_member_event_text(dict) {
    var info = dict.content, prev = dict.prev_content

    if (! prev || (info.membership != prev.membership)) {
        switch (info.membership) {
            case "join":
                return "joined the room."
                break

            case "invite":
                var name = Backend.getUser(dict.state_key).display_name
                var name = name === dict.state_key ? info.displayname : name
                return "invited " + name + " to the room."
                break

            case "leave":
                return "left the room."
                break

            case "ban":
                return "was banned from the room."
                break
        }
    }

    var changed = []

    if (prev && (info.avatar_url != prev.avatar_url)) {
        changed.push("profile picture")
    }

    if (prev && (info.displayname != prev.displayname)) {
        changed.push("display name from \"" +
                     (prev.displayname || dict.state_key) + '" to "' +
                     (info.displayname || dict.state_key) + '"')
    }

    if (changed.length > 0) {
        return "changed their " + changed.join(" and ") + "."
    }

    return ""
}


function get_typing_users_text(account_id, room_id) {
    var names = []
    var room  = Backend.models.rooms.get(account_id)
                .getWhere("room_id", room_id)

    for (var i = 0; i < room.typing_users.length; i++) {
        names.push(Backend.getUser(room.typing_users[i]).display_name)
    }

    if (names.length < 1) { return "" }

    return "🖋 " +
           [names.slice(0, -1).join(", "), names.slice(-1)[0]]
           .join(names.length < 2 ? "" : " and ") +
           (names.length > 1 ? " are" : " is") + " typing…"
}
