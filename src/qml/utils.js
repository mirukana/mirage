// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.


function hsluv(hue, saturation, lightness, alpha=1.0) {
    let rgb = py.callSync("hsluv", [hue, saturation, lightness])
    return Qt.rgba(rgb[0], rgb[1], rgb[2], alpha)
}


function hsl(hue, saturation, lightness) {
    return hsla(hue, saturation, lightness)
}


function hsla(hue, saturation, lightness, alpha=1.0) {
    // Convert standard hsla(0-360, 1-100, 1-100, 0-1) to Qt format
    return Qt.hsla(hue / 360, saturation / 100, lightness / 100, alpha)
}


function arrayToModelItem(keysName, array) {
    // Convert an array to an object suitable to be in a model, example:
    // [1, 2, 3] → [{keysName: 1}, {keysName: 2}, {keysName: 3}]
    let items = []

    for (let item of array) {
        let obj       = {}
        obj[keysName] = item
        items.push(obj)
    }
    return items
}


function hueFrom(string) {
    // Calculate and return a unique hue between 0 and 360 for the string
    let hue = 0
    for (let i = 0; i < string.length; i++) {
        hue += string.charCodeAt(i) * 99
    }
    return hue % 360
}


function nameColor(name) {
    return hsl(
        hueFrom(name),
        theme.controls.displayName.saturation,
        theme.controls.displayName.lightness,
    )
}


function coloredNameHtml(name, userId, displayText=null) {
    // substring: remove leading @
    return "<font color='" + nameColor(name || userId.substring(1)) + "'>" +
           escapeHtml(displayText || name || userId) +
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


function processedEventText(ev) {
    if (ev.eventType == "RoomMessageEmote") {
        let name = users.find(ev.senderId).displayName
        return "<i>" + coloredNameHtml(name) + " " + ev.content + "</i>"
    }

    if (ev.eventType.startsWith("RoomMessage")) { return ev.content }

    let name = users.find(ev.senderId).displayName
    let text = qsTr(ev.content).arg(coloredNameHtml(name, ev.senderId))

    if (text.includes("%2") && ev.targetUserId) {
        let tname = users.find(ev.targetUserId).displayName
        text = text.arg(coloredNameHtml(tname, ev.targetUserId))
    }

    return text
}


function filterMatches(filter, text) {
    filter = filter.toLowerCase()
    text   = text.toLowerCase()

    let words = filter.split(" ")

    for (let word of words) {
        if (word && ! text.includes(word)) {
            return false
        }
    }
    return true
}


function thumbnailParametersFor(width, height) {
    // https://matrix.org/docs/spec/client_server/latest#thumbnails

    if (width > 640 || height > 480)
        return {width: 800, height: 600, fillMode: Image.PreserveAspectFit}

    if (width > 320 || height > 240)
        return {width: 640, height: 480, fillMode: Image.PreserveAspectFit}

    if (width >  96 || height >  96)
        return {width: 320, height: 240, fillMode: Image.PreserveAspectFit}

    if (width >  32 || height >  32)
        return {width: 96, height: 96, fillMode: Image.PreserveAspectCrop}

    return {width: 32, height: 32, fillMode: Image.PreserveAspectCrop}
}


function minutesBetween(date1, date2) {
    return Math.round((((date2 - date1) % 86400000) % 3600000) / 60000)
}
