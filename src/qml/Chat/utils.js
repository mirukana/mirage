function getLeftBannerText(leftEvent) {
    if (! leftEvent) {
        return "You are not member of this room."
    }

    var info   = leftEvent.content
    var prev   = leftEvent.prev_content
    var reason = info.reason ? (" Reason: " + info.reason) : ""

    if (leftEvent.state_key === leftEvent.sender) {
        return (prev && prev.membership === "invite" ?
                "You declined to join the room." : "You left the room.") +
               reason
    }

    if (info.membership)

    var name = Backend.users.get(leftEvent.sender).displayName.value

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
        return Backend.users.get(accountId).displayName.value
    }

    return Backend.users.get(leftEvent.sender).displayName.value
}


function getTypingMembersText(users, ourAccountId) {
    var names = []

    for (var i = 0; i < users.length; i++) {
        if (users[i] !== ourAccountId) {
            names.push(Backend.users.get(users[i]).displayName.value)
        }
    }

    if (names.length < 1) { return "" }

    return "🖋 " +
           [names.slice(0, -1).join(", "), names.slice(-1)[0]]
           .join(names.length < 2 ? "" : " and ") +
           (names.length > 1 ? " are" : " is") + " typing…"
}
