function arrayToModelItem(keys_name, array) {
    // Convert an array to an object suitable to be in a model, example:
    // [1, 2, 3] → [{keys_name: 1}, {keys_name: 2}, {keys_name: 3}]
    var items = []

    for (var i = 0; i < array.length; i++) {
        var obj        = {}
        obj[keys_name] = array[i]
        items.push(obj)
    }
    return items
}


function hueFrom(string) {
    // Calculate and return a unique hue between 0 and 1 for the string
    var hue = 0
    for (var i = 0; i < string.length; i++) {
        hue += string.charCodeAt(i) * 99
    }
    return hue % 360 / 360
}


function avatarColor(name) {
   return Qt.hsla(
       hueFrom(name),
       theme.avatar.background.saturation,
       theme.avatar.background.lightness,
       theme.avatar.background.alpha
   )
}


function nameColor(name) {
    return Qt.hsla(
        hueFrom(name),
        theme.displayName.saturation,
        theme.displayName.lightness,
        1
    )
}


function coloredNameHtml(name, alt_id) {
    // substring: remove leading @
    return "<font color='" + nameColor(name || alt_id.substring(1)) + "'>" +
           escapeHtml(name || alt_id) +
           "</font>"
}


function escapeHtml(string) {
    // Replace special HTML characters by encoded alternatives
    return string.replace("&", "&amp;")
                 .replace("<", "&lt;")
                 .replace(">", "&gt;")
                 .replace('"', "&quot;")
                 .replace("'", "&#039;")
}


function eventIsMessage(ev) {
    return /^RoomMessage($|[A-Z])/.test(ev.eventType)
}


function translatedEventContent(ev) {
    // ev: timelines item
    if (ev.translatable == false) { return ev.content }

    // %S → sender display name
    var name = users.getUser(ev.senderId).displayName
    var text = ev.content.replace("%S", coloredNameHtml(name, ev.senderId))

    // %T → target (event state_key) display name
    if (ev.targetUserId) {
        var tname = users.getUser(ev.targetUserId).displayName
        text = text.replace("%T", coloredNameHtml(tname, ev.targetUserId))
    }

    text = qsTr(text)
    if (ev.translatable == true) { return text }

    // Else, model.translatable should be an array of args
    for (var i = 0; ev.translatable.length; i++) {
        text = text.arg(ev.translatable[i])
    }
    return text
}
