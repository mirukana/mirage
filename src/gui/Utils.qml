// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

QtObject {
    function makeObject(urlComponent, parent=null, properties={},
                        callback=null) {
        let comp = urlComponent

        if (! Qt.isQtObject(urlComponent)) {
            // It's an url or path string to a component
            comp = Qt.createComponent(urlComponent, Component.Asynchronous)
        }

        let ready = false

        comp.statusChanged.connect(status => {
            if ([Component.Null, Component.Error].includes(status)) {
               console.error("Failed creating component: ", comp.errorString())

            } else if (! ready && status === Component.Ready) {
                let incu = comp.incubateObject(
                    parent, properties, Qt.Asynchronous,
                )

                if (incu.status === Component.Ready) {
                    if (callback) callback(incu.object)
                    ready = true
                    return
                }

                incu.onStatusChanged = (istatus) => {
                    if (incu.status === Component.Error) {
                        console.error("Failed incubating object: ",
                                      incu.errorString())

                    } else if (istatus === Component.Ready &&
                               callback && ! ready) {
                        if (callback) callback(incu.object)
                        ready = true
                    }
                }
            }
        })

        if (comp.status === Component.Ready) comp.statusChanged(comp.status)
    }


    function makePopup(urlComponent, parent=null, properties={}, callback=null,
                       autoDestruct=true) {
        makeObject(urlComponent, parent, properties, (popup) => {
            popup.open()
            if (autoDestruct) popup.closed.connect(() => { popup.destroy() })
            if (callback)     callback(popup)
        })
    }


    function sum(array) {
        if (array.length < 1) return 0
        return array.reduce((a, b) => (isNaN(a) ? 0 : a) + (isNaN(b) ? 0 : b))
    }


    function isEmptyObject(obj) {
        return Object.entries(obj).length === 0 && obj.constructor === Object
    }


    function objectUpdate(current, update) {
        return Object.assign({}, current, update)
    }


    function objectUpdateRecursive(current, update) {
        for (const key of Object.keys(update)) {
            if ((key in current) && typeof(current[key]) === "object" &&
                    typeof(update[key]) === "object") {
                objectUpdateRecursive(current[key], update[key])
            } else {
                current[key] = update[key]
            }
        }
    }


    function numberWrapAt(num, max) {
        return num < 0 ? max + (num % max) : (num % max)
    }


    function hsluv(hue, saturation, lightness, alpha=1.0) {
        return CppUtils.hsluv(hue, saturation, lightness, alpha)
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


    function coloredNameHtml(name, userId, displayText=null,
                             disambiguate=false) {
        // substring: remove leading @
        return `<font color="${nameColor(name || userId.substring(1))}">` +
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
        if (ev.event_type === "RoomMessageEmote")
        return coloredNameHtml(ev.sender_name, ev.sender_id) + " " +
               ev.content

        let unknown = ev.event_type === "RoomMessageUnknown"

        if (ev.event_type.startsWith("RoomMessage") && ! unknown)
            return ev.content

        if (ev.event_type.startsWith("RoomEncrypted")) return ev.content

        let text = qsTr(ev.content).arg(
            coloredNameHtml(ev.sender_name, ev.sender_id)
        )

        if (text.includes("%2") && ev.target_id)
            text = text.arg(coloredNameHtml(ev.target_name, ev.target_id))

        return text
    }


    function filterMatches(filter, text) {
        let filter_lower = filter.toLowerCase()

        if (filter_lower === filter) {
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


    function fitSize(minWidth, minHeight, width, height, maxWidth, maxHeight) {
        if (width >= height) {
            let new_width = Math.min(Math.max(width, minWidth), maxWidth)
            return Qt.size(new_width, height / (width / new_width))
        }

        let new_height = Math.min(Math.max(height, minHeight), maxHeight)
        return Qt.size(width / (height / new_height), new_height)
    }


    function minutesBetween(date1, date2) {
        return ((date2 - date1) / 1000) / 60
    }


    function dateIsDay(date, dayDate) {
        return date.getDate() === dayDate.getDate() &&
               date.getMonth() === dayDate.getMonth() &&
               date.getFullYear() === dayDate.getFullYear()
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

        if (seconds < 10) seconds = `0${seconds}`
        if (hours < 1)    return `${minutes}:${seconds}`

        if (minutes < 10) minutes = `0${minutes}`
        return `${hours}:${minutes}:${seconds}`
    }


    function round(floatNumber) {
        return parseFloat(floatNumber.toFixed(2))
    }


    function getItem(array, mainKey, value) {
        for (let i = 0; i < array.length; i++) {
            if (array[i][mainKey] === value) { return array[i] }
        }
        return undefined
    }


    function flickPages(flickable, pages) {
        // Adapt velocity and deceleration for the number of pages to flick.
        // If this is a repeated flicking, flick faster than a single flick.
        if (! flickable.interactive && flickable.allowDragging) return

        const futureVelocity  = -flickable.height * pages
        const currentVelocity = -flickable.verticalVelocity
        const goFaster        =
            (futureVelocity < 0 && currentVelocity < futureVelocity / 2) ||
            (futureVelocity > 0 && currentVelocity > futureVelocity / 2)

        const normalDecel  = flickable.flickDeceleration
        const fastMultiply = pages && 8 / (1 - Math.log10(Math.abs(pages)))
        const magicNumber  = 2.5

        flickable.flickDeceleration = Math.max(
            goFaster ? normalDecel : -Infinity,
            Math.abs(normalDecel * magicNumber * pages),
        )

        flickable.flick(
            0, futureVelocity * magicNumber * (goFaster ? fastMultiply : 1),
        )

        flickable.flickDeceleration = normalDecel
    }


    function flickToTop(flickable) {
        if (! flickable.interactive && flickable.allowDragging) return
        if (flickable.visibleArea.yPosition < 0) return

        flickable.contentY -= flickable.contentHeight
        flickable.returnToBounds()
        flickable.flick(0, -100)  // Force the delegates to load
    }


    function flickToBottom(flickable) {
        if (! flickable.interactive && flickable.allowDragging) return
        if (flickable.visibleArea.yPosition < 0) return

        flickable.contentY = flickable.contentHeight - flickable.height
        flickable.returnToBounds()
        flickable.flick(0, 100)
    }


    function urlExtension(url) {
        return url.toString().split("/").slice(-1)[0].split("?")[0].split(".")
                  .slice(-1)[0].toLowerCase()
    }


    function sendFile(userId, roomId, path, onSuccess, onError) {
        py.callClientCoro(
            userId, "send_file", [roomId, path], onSuccess, onError,
        )
    }
}
