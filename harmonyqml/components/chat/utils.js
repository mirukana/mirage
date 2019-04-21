function getEventText(type, dict) {
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
            return getHistoryVisibilityEventText(dict)
            break

        case "PowerLevelsEvent":
            return "changed the room's permissions."

        case "RoomMemberEvent":
            return getMemberEventText(dict)
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


function getHistoryVisibilityEventText(dict) {
    switch (dict.history_visibility) {
        case "shared":
            var end = "all room members."
            break

        case "world_readable":
            var end = "any member or outsider."
            break

        case "joined":
            var end = "all room members, since the point they joined."
            break

        case "invited":
            var end = "all room members, since the point they were invited."
            break
        }

    return "made future history visible to " + end
}


function getStateDisplayName(dict) {
    // The dict.content.displayname may be outdated, prefer
    // retrieving it fresh
    var name = Backend.getUserDisplayName(dict.state_key, false)
    return name === dict.state_key ?
           dict.content.displayname : name.result()
}


function getMemberEventText(dict) {
    var info = dict.content, prev = dict.prev_content

    if (! prev || (info.membership != prev.membership)) {
        var reason = info.reason ? (" Reason: " + info.reason) : ""

        switch (info.membership) {
            case "join":
                return prev && prev.membership === "invite" ?
                       "accepted the invitation." : "joined the room."
                break

            case "invite":
                return "invited " + getStateDisplayName(dict) + " to the room."
                break

            case "leave":
                if (dict.state_key === dict.sender) {
                    return (prev && prev.membership === "invite" ?
                            "declined the invitation." : "left the room.") +
                           reason
                }

                var name = getStateDisplayName(dict)
                return (prev && prev.membership === "invite" ?
                        "withdrew " + name + "'s invitation." :

                        prev && prev.membership == "ban" ?
                        "unbanned " + name + " from the room." :

                        "kicked out " + name  + " from the room.") +
                       reason
                break

            case "ban":
                var name = getStateDisplayName(dict)
                return "banned " + name + " from the room." + reason
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


function getLeftBannerText(leftEvent) {
    if (! leftEvent) {
        return "You are not member of this room."
    }

    var info   = leftEvent.content
    var prev   = leftEvent.prev_content
    var reason = info.reason ? (" Reason: " + info.reason) : ""

    if (leftEvent.state_key === leftEvent.sender) {
        return (prev && prev.membership === "invite" ?
                "You declined to join this room." : "You left the room.") +
               reason
    }

    if (info.membership)

    var name = Backend.getUserDisplayName(leftEvent.sender, false).result()

    return "<b>" + name + "</b> " +
           (info.membership == "ban" ?
            "banned you from the room." :

            prev && prev.membership === "invite" ?
            "canceled your invitation." :

            prev && prev.membership == "ban" ?
            "unbanned you from the room." :

            "kicked you out of the room.") +
           reason
}


function getLeftBannerAvatarName(leftEvent, accountId) {
    if (! leftEvent || leftEvent.state_key == leftEvent.sender) {
        return Backend.getUserDisplayName(accountId, false).result()
    }

    return Backend.getUserDisplayName(leftEvent.sender, false).result()
}


function getTypingUsersText(users, ourAccountId) {
    var names = []

    for (var i = 0; i < users.length; i++) {
        if (users[i] !== ourAccountId) {
            names.push(Backend.getUserDisplayName(users[i], false).result())
        }
    }

    if (names.length < 1) { return "" }

    return "🖋 " +
           [names.slice(0, -1).join(", "), names.slice(-1)[0]]
           .join(names.length < 2 ? "" : " and ") +
           (names.length > 1 ? " are" : " is") + " typing…"
}
