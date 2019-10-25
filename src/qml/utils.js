function makeObject(url, parent=null, properties={}, callback=null) {
    let comp  = Qt.createComponent(url, Component.Asynchronous)
    let ready = false

    comp.statusChanged.connect(status => {
        if ([Component.Null, Component.Error].includes(status)) {
           console.error("Failed creating component: ", comp.errorString())

        } else if (! ready && status === Component.Ready) {
            let incu = comp.incubateObject(parent, properties, Qt.Asynchronous)

            if (incu.status === Component.Ready) {
                if (callback) callback(incu.object)
                ready = true
                return
            }

            incu.onStatusChanged = (istatus) => {
                if (incu.status === Component.Error) {
                    console.error("Failed incubating object: ",
                                  incu.errorString())

                } else if (istatus === Component.Ready && callback && ! ready) {
                    if (callback) callback(incu.object)
                    ready = true
                }
            }
        }
    })

    if (comp.status === Component.Ready) comp.statusChanged(comp.status)
}


function makePopup(url, parent=null, properties={}, callback=null,
                   autoDestruct=true) {
    makeObject(url, parent, properties, (popup) => {
        popup.open()
        if (autoDestruct) popup.closed.connect(() => { popup.destroy() })
        if (callback)     callback(popup)
    })
}


function debug(target, callback=null) {
    return Utils.makeObject("DebugConsole.qml", target, { target }, callback)
}


function isEmptyObject(obj) {
    return Object.entries(obj).length === 0 && obj.constructor === Object
}


function numberWrapAt(num, max) {
    return num < 0 ? max + (num % max) : (num % max)
}


function hsluv(hue, saturation, lightness, alpha=1.0) {
    hue = numberWrapAt(hue, 360)
    let rgb = py.callSync("hsluv", [hue, saturation, lightness])
    return Qt.rgba(rgb[0], rgb[1], rgb[2], alpha)
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
    return hsluv(
        hueFrom(name),
        theme.controls.displayName.saturation,
        theme.controls.displayName.lightness,
    )
}


function coloredNameHtml(name, userId, displayText=null, disambiguate=false) {
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
    if (ev.event_type == "RoomMessageEmote") {
        return "<i>" +
               coloredNameHtml(ev.sender_name, ev.sender_id) + " " +
               ev.content + "</i>"
    }

    if (ev.event_type.startsWith("RoomMessage")) { return ev.content }

    let text = qsTr(ev.content).arg(
        coloredNameHtml(ev.sender_name, ev.sender_id)
    )

    if (text.includes("%2") && ev.target_id) {
        text = text.arg(coloredNameHtml(ev.target_name, ev.target_id))
    }

    return text
}


function filterMatches(filter, text) {
    let filter_lower = filter.toLowerCase()

    if (filter_lower == filter) {
        // Consider case only if filter isn't all lowercase (smart case)
        filter = filter_lower
        text   = text.toLowerCase()
    }

    for (let word of filter.split(" ")) {
        if (word && ! text.includes(word)) {
            return false
        }
    }
    return true
}


function filterModelSource(source, filter_text, property="filter_string") {
    if (! filter_text) return source
    let results = []

    for (let i = 0;  i < source.length; i++) {
        if (filterMatches(filter_text, source[i][property])) {
            results.push(source[i])
        }
    }

    return results
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


function fitSize(width, height, max) {
    if (width >= height) {
        let new_width = Math.min(width, max)
        return Qt.size(new_width, height / (width / new_width))
    }
    let new_height = Math.min(height, max)
    return Qt.size(width / (height / new_height), new_height)
}


function minutesBetween(date1, date2) {
    return ((date2 - date1) / 1000) / 60
}


function dateIsDay(date, dayDate) {
    return date.getDate() == dayDate.getDate() &&
           date.getMonth() == dayDate.getMonth() &&
           date.getFullYear() == dayDate.getFullYear()
}


function dateIsToday(date) {
    return dateIsDay(date, new Date())
}


function dateIsYesterday(date) {
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    return dateIsDay(date, yesterday)
}


function formatTime(time, seconds=true) {
    return Qt.formatTime(
        time,

        Qt.locale().timeFormat(
            seconds ? Locale.LongFormat : Locale.NarrowFormat
        ).replace(/\./g, ":").replace(/ t$/, "")
        // en_DK.UTF-8 locale wrongfully gives "." separators;
        // also remove the timezone at the end
    )
}


function formatDuration(milliseconds) {
    let totalSeconds = milliseconds / 1000

    let hours   = Math.floor(totalSeconds / 3600)
    let minutes = Math.floor((totalSeconds % 3600) / 60)
    let seconds = Math.floor(totalSeconds % 60)

    if (seconds < 10) seconds = "0" + seconds
    if (hours < 1)    return minutes + ":" + seconds

    if (minutes < 10) minutes = "0" + minutes
	return hours + ":" + minutes + ":" + seconds
}


function round(float) {
    return parseFloat(float.toFixed(2))
}


function getItem(array, mainKey, value) {
    for (let i = 0; i < array.length; i++) {
        if (array[i][mainKey] === value) { return array[i] }
    }
    return undefined
}


function smartVerticalFlick(flickable, baseVelocity, fastMultiply=4) {
    if (! flickable.interactive && flickable.enableFlicking) return

    baseVelocity = -baseVelocity
    let vel      = -flickable.verticalVelocity
    let fast     = (baseVelocity < 0 && vel < baseVelocity / 2) ||
                   (baseVelocity > 0 && vel > baseVelocity / 2)

    flickable.flick(0, baseVelocity * (fast ? fastMultiply : 1))
}


function flickToTop(flickable) {
    if (! flickable.interactive && flickable.enableFlicking) return
    if (flickable.visibleArea.yPosition < 0) return

    flickable.contentY -= flickable.contentHeight
    flickable.returnToBounds()
    flickable.flick(0, -100)  // Force the delegates to load
}


function flickToBottom(flickable) {
    if (! flickable.interactive && flickable.enableFlicking) return
    if (flickable.visibleArea.yPosition < 0) return

    flickable.contentY = flickTarget.contentHeight - flickTarget.height
    flickable.returnToBounds()
    flickable.flick(0, 100)
}


function urlExtension(url) {
    return url.toString().split("/").slice(-1)[0].split("?")[0].split(".")
              .slice(-1)[0].toLowerCase()
}
