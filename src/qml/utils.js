function stripUserId(user_id) {
    // Remove leading @
    return user_id.substring(1)
}


function stripRoomName(name) {
    // Remove leading # (aliases)
    return name[0] == "#" ? name.substring(1) : name
}


function hueFrom(string) {
    // Calculate and return a unique hue between 0 and 1 for the string
    var hue = 0
    for (var i = 0; i < string.length; i++) {
        hue += string.charCodeAt(i) * 99
    }
    return hue % 360 / 360
}


function avatarHue(name) {
   return Qt.hsla(
       hueFrom(name),
       HStyle.avatar.background.saturation,
       HStyle.avatar.background.lightness,
       HStyle.avatar.background.alpha
   )
}


function nameHue(name) {
    return Qt.hsla(
        hueFrom(name),
        HStyle.displayName.saturation,
        HStyle.displayName.lightness,
        1
    )
}


function escapeHtml(string) {
    // Replace special HTML characters by encoded alternatives
    return string.replace("&", "&amp;")
                 .replace("<", "&lt;")
                 .replace(">", "&gt;")
                 .replace('"', "&quot;")
                 .replace("'", "&#039;")
}


function translatedEventContent(ev) {
    // ev: models.timelines item
    if (ev.translatable == false) { return ev.content }

    // %S → sender display name
    var name = models.users.getUser(ev.senderId).displayName
    var text = ev.content.replace(
        "%S",
        "<font color='" + nameHue(name || stripUserId(ev.senderId)) + "'>" +
        escapeHtml(name || ev.senderId) +
        "</font>"
    )

    // %T → target (event state_key) display name
    if (ev.targetUserId) {
        var target_name = models.users.getUser(ev.targetUserId).displayName
        text = text.replace(
            "%T",
            "<font color='" +
            nameHue(target_name || stripUserId(ev.targetUserId)) +
            "'>" +
            escapeHtml(target_name || ev.targetUserId) +
            "</font>"
        )
    }

    text = qsTr(text)
    if (model.translatable == true) { return text }

    // Else, model.translatable should be an array of args
    for (var i = 0; model.translatable.length; i++) {
        text = text.arg(model.translatable[i])
    }
    return text
}
