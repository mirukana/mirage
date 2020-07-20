// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import Clipboard 0.1
import "../../.."
import "../../../Base"
import "../../../PythonBridge"
import "../../../ShortcutBundles"

Rectangle {
    property alias eventList: eventList


    color: theme.chat.eventList.background

    HShortcut {
        sequences: window.settings.keys.unfocusOrDeselectAllMessages
        onActivated: {
            eventList.selectedCount ?
            eventList.checked = {} :
            eventList.currentIndex = -1
        }
    }

    HShortcut {
        sequences: window.settings.keys.focusPreviousMessage
        onActivated: eventList.incrementCurrentIndex()
    }

    HShortcut {
        sequences: window.settings.keys.focusNextMessage
        onActivated:
            eventList.currentIndex === 0 ?
            eventList.currentIndex = -1 :
            eventList.decrementCurrentIndex()
    }

    HShortcut {
        active: eventList.currentItem
        sequences: window.settings.keys.toggleSelectMessage
        onActivated: eventList.toggleCheck(eventList.currentIndex)
    }

    HShortcut {
        active: eventList.currentItem
        sequences: window.settings.keys.selectMessagesUntilHere
        onActivated:
            eventList.checkFromLastToHere(eventList.currentIndex)
    }

    HShortcut {
        readonly property var events:
            eventList.selectedCount ?
            eventList.redactableCheckedEvents :

            eventList.currentItem &&
            eventList.canRedact(eventList.currentItem.currentModel) ?
            [eventList.currentItem.currentModel] :

            eventList.currentItem ?
            [] :
            null

        function findLastRemovableDelegate() {
            for (let i = 0; i < eventList.model.count && i <= 1000; i++) {
                const event = eventList.model.get(i)
                if (eventList.canRedact(event) &&
                    mainUI.accountIds.includes(event.sender_id)) return [event]
            }
            return []
        }

        enabled: (events && events.length > 0) || events === null
        sequences: window.settings.keys.removeFocusedOrSelectedMessages
        onActivated: utils.makePopup(
            "Popups/RedactPopup.qml",
            {
                preferUserId: chat.userId,
                roomId: chat.roomId,

                eventSenderAndIds:
                    (events || findLastRemovableDelegate()).map(
                        ev => [ev.sender_id, ev.id],
                    ),

                isLast: ! events,

                onlyOwnMessageWarning:
                    ! chat.roomInfo.can_redact_all &&
                    events &&
                    events.length < eventList.selectedCount
            }
        )
    }

    HShortcut {
        sequences: window.settings.keys.replyToFocusedOrLastMessage
        onActivated: {
            let event = eventList.model.get(0)

            if (eventList.currentIndex !== -1) {
                event = eventList.model.get(eventList.currentIndex)
            } else if (eventList.selectedCount) {
                event = eventList.getSortedChecked.slice(-1)[0]
            } else {
                // Find most recent event that wasn't sent by us
                for (let i = 0; i < eventList.model.count && i <= 1000; i++) {
                    const potentialEvent = eventList.model.get(i)

                    if (potentialEvent.sender_id !== chat.userId) {
                        event = potentialEvent
                        break
                    }
                }
            }

            if (! event) return

            chat.replyToEventId     = event.id
            chat.replyToUserId      = event.sender_id
            chat.replyToDisplayName = event.sender_name
        }
    }

    HShortcut {
        sequences: window.settings.keys.openMessagesLinks  // XXX: rename
        onActivated: {
            let indice = []

            if (eventList.selectedCount) {
                indice = eventList.checkedIndice
            } else if (eventList.currentIndex !== -1) {
                indice = [eventList.currentIndex]
            } else {
                // Find most recent event that's a media or contains links
                for (let i = 0; i < eventList.model.count && i <= 1000; i++) {
                    const ev    = eventList.model.get(i)
                    const links = JSON.parse(ev.links)

                    if (ev.media_url || ev.thumbnail_url || links.length) {
                        indice = [i]
                        break
                    }
                }
            }

            for (const i of indice.sort().reverse()) {
                const event = eventList.model.get(i)

                if (event.media_url || event.thumbnail_url) {
                    eventList.getMediaType(event) === Utils.Media.Image ?
                    eventList.openImageViewer(event) :
                    eventList.openMediaExternally(event)

                    continue
                }

                for (const url of JSON.parse(event.links)) {
                    utils.getLinkType(url) === Utils.Media.Image ?
                    eventList.openImageViewer(event, url) :
                    Qt.openUrlExternally(url)
                }
            }
        }
    }

    HShortcut {
        active: eventList.currentItem
        sequences: window.settings.keys.debugFocusedMessage
        onActivated: mainUI.debugConsole.toggle(
            eventList.currentItem.eventContent, "t.parent.json()",
        )
    }

    HShortcut {
        sequences: window.settings.keys.clearRoomMessages
        onActivated: utils.makePopup(
            "Popups/ClearMessagesPopup.qml",
            {
                userId: window.uiState.pageProperties.userId,
                roomId: window.uiState.pageProperties.roomId,
                preClearCallback: eventList.uncheckAll,
            }
        )
    }

    FlickShortcuts {
        active: chat.composerHasFocus
        flickable: eventList
    }


    HListView {
        id: eventList

        property string inviter: chat.roomInfo.inviter || ""
        property real yPos: visibleArea.yPosition
        property bool canLoad: true
        property bool loading: false

        property Future updateMarkerFuture: null

        property bool ownEventsOnLeft:
            window.settings.ownMessagesOnLeftAboveWidth < 0 ?
            false :
            width > window.settings.ownMessagesOnLeftAboveWidth * theme.uiScale

        property string delegateWithSelectedText: ""
        property string selectedText: ""

        property alias cursorShape: cursorShapeArea.cursorShape

        readonly property var thumbnailCachedPaths: ({})  // {event.id: path}

        readonly property var redactableCheckedEvents:
            getSortedChecked().filter(ev => eventList.canRedact(ev))

        function copySelectedDelegates() {
            if (eventList.selectedText) {
                Clipboard.text = eventList.selectedText
                return
            }

            if (! eventList.selectedCount && eventList.currentIndex !== -1) {
                const model  = eventList.model.get(eventList.currentIndex)
                const source = JSON.parse(model.source)

                Clipboard.text =
                    "body" in source ?
                    source.body :
                    utils.stripHtmlTags(utils.processedEventText(model))

                return
            }

            const contents = []

            for (const model of eventList.getSortedChecked()) {
                const source = JSON.parse(model.source)

                contents.push(
                    "body" in source ?
                    source.body :
                    utils.stripHtmlTags(utils.processedEventText(model))
                )
            }

            Clipboard.text = contents.join("\n\n")
        }

        function canRedact(eventModel) {
            return eventModel.event_type !== "RedactedEvent" &&
                   (chat.roomInfo.can_redact_all ||
                    mainUI.accountIds.includes(eventModel.sender_id))
        }

        function canCombine(item, itemAfter) {
            if (! item || ! itemAfter) return false

            return Boolean(
                ! canTalkBreak(item, itemAfter) &&
                ! canDayBreak(item, itemAfter) &&
                item.sender_id === itemAfter.sender_id &&
                utils.minutesBetween(item.date, itemAfter.date) <= 5
            )
        }

        function canTalkBreak(item, itemAfter) {
            if (! item || ! itemAfter) return false

            return Boolean(
                ! canDayBreak(item, itemAfter) &&
                utils.minutesBetween(item.date, itemAfter.date) >= 20
            )
        }

        function canDayBreak(item, itemAfter) {
            if (itemAfter && itemAfter.event_type === "RoomCreateEvent")
                return true

            if (! item || ! itemAfter || ! item.date || ! itemAfter.date)
                return false

            return item.date.getDate() !== itemAfter.date.getDate()
        }

        function loadPastEvents() {
            // try/catch blocks to hide pyotherside error when the
            // component is destroyed but func is still running

            try {
                eventList.canLoad = false
                eventList.loading = true

                py.callClientCoro(
                    chat.userId,
                    "load_past_events",
                    [chat.roomId],
                    moreToLoad => {
                        try {
                            eventList.canLoad = moreToLoad

                            // Call yPosChanged() to run this func again
                            // if the loaded messages aren't enough to fill
                            // the screen.
                            if (moreToLoad) yPosChanged()

                            eventList.loading = false
                        } catch (err) {
                            return
                        }
                    }
                )
            } catch (err) {
                return
            }
        }

        function getMediaType(event) {
            if (event.event_type === "RoomAvatarEvent")
                return Utils.Media.Image

            const mainType   = event.media_mime.split("/")[0].toLowerCase()
            const fileEvents = ["RoomMessageFile", "RoomEncryptedFile"]

            return (
                mainType === "image" ? Utils.Media.Image :
                mainType === "video" ? Utils.Media.Video :
                mainType === "audio" ? Utils.Media.Audio :
                fileEvents.includes(event.event_type) ? Utils.Media.File :
                null
            )
        }

        function isAnimated(event) {
            return (
                event.media_mime === "image/gif" ||
                utils.urlExtension(event.media_url).toLowerCase() === "gif"
            )
        }

        function getThumbnailTitle(event) {
            return event.media_title.replace(
                /\.[^\.]+$/,
                event.thumbnail_mime === "image/jpeg"    ? ".jpg" :
                event.thumbnail_mime === "image/png"     ? ".png" :
                event.thumbnail_mime === "image/gif"     ? ".gif" :
                event.thumbnail_mime === "image/tiff"    ? ".tiff" :
                event.thumbnail_mime === "image/svg+xml" ? ".svg" :
                event.thumbnail_mime === "image/webp"    ? ".webp" :
                event.thumbnail_mime === "image/bmp"     ? ".bmp" :
                ".thumbnail"
            ) || utils.urlFileName(event.media_url)
        }

        function openImageViewer(event, forLink="") {
            // if forLink is empty, this must be a media event

            const title =
                event.media_title || utils.urlFileName(event.media_url)

            // The thumbnail/cached path will be the full GIF
            const fullMxc =
                forLink || (isAnimated(event) ? "" : event.media_url)

            utils.makePopup(
                "Popups/ImageViewerPopup.qml",
                {
                    thumbnailTitle: getThumbnailTitle(event),
                    thumbnailMxc: event.thumbnail_url,
                    thumbnailPath: eventList.thumbnailCachedPaths[event.id],
                    thumbnailCryptDict: JSON.parse(event.thumbnail_crypt_dict),

                    fullTitle: title,
                    fullMxc: fullMxc,
                    fullCryptDict: JSON.parse(event.media_crypt_dict),

                    overallSize: Qt.size(
                        event.media_width ||
                        event.thumbnail_width ||
                        implicitWidth || // XXX
                        800,

                        event.media_height ||
                        event.thumbnail_height ||
                        implicitHeight || // XXX
                        600,
                    )
                },
                obj => {
                    obj.openExternallyRequested.connect(() =>
                        forLink ?
                        Qt.openUrlExternally(forLink) :
                        eventList.openMediaExternally(event)
                    )
                },
            )
        }

        function getLocalOrDownloadMedia(event, callback) {
            print("Downloading " + event.media_url + " ...")

            const args = [
                event.media_url,
                event.media_title,
                JSON.parse(event.media_crypt_dict),
            ]

            py.callCoro("media_cache.get_media", args, path => {
                print("Done: " + path)
                callback(path)
            })
        }

        function openMediaExternally(event) {
            eventList.getLocalOrDownloadMedia(event, Qt.openUrlExternally)
        }

        anchors.fill: parent
        clip: true
        keyNavigationWraps: false
        leftMargin: theme.spacing
        rightMargin: theme.spacing
        topMargin: theme.spacing
        bottomMargin: theme.spacing
        verticalLayoutDirection: ListView.BottomToTop

        // Keep x scroll pages cached, to limit images having to be
        // reloaded from network.
        cacheBuffer: Screen.desktopAvailableHeight * 2

        model: ModelStore.get(chat.userId, chat.roomId, "events")
        delegate: EventDelegate {}

        highlight: Rectangle {
            color: theme.chat.message.focusedHighlight
            opacity: theme.chat.message.focusedHighlightOpacity
        }

        // Since the list is BottomToTop, this is actually a header
        footer: Item {
            width: eventList.width
            height: (button.height + theme.spacing * 2) * opacity
            opacity: eventList.loading ? 1 : 0
            visible: opacity > 0

            Behavior on opacity { HNumberAnimation {} }

            HButton {
                readonly property bool offline:
                    chat.userInfo.presence === "offline"

                id: button
                width: Math.min(parent.width, implicitWidth)
                anchors.centerIn: parent

                loading: parent.visible && ! offline
                icon.name: offline ? "feature-unavailable-offline" : ""
                icon.color:
                    offline ?
                    theme.colors.negativeBackground :
                    theme.icons.colorize
                text:
                    offline ?
                    qsTr("Cannot load history offline") :
                    qsTr("Loading previous messages...")

                enableRadius: true
                iconItem.small: true
            }
        }

        onYPosChanged:
            if (canLoad && yPos < 0.1) Qt.callLater(loadPastEvents)

        // When an invited room becomes joined, we should now be able to
        // fetch past events.
        onInviterChanged: canLoad = true

        MouseArea {
            id: cursorShapeArea
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
        }
    }

    Timer {
        interval: Math.max(100, window.settings.markRoomReadMsecDelay)

        running:
            ! eventList.updateMarkerFuture &&
            (
                chat.roomInfo.unreads ||
                chat.roomInfo.highlights ||
                chat.roomInfo.local_unreads ||
                chat.roomInfo.local_highlights
            ) &&
            Qt.application.state === Qt.ApplicationActive &&
            (eventList.contentY + eventList.height) > -50

        onTriggered: {
            for (let i = 0; i < eventList.model.count; i++) {
                const item = eventList.model.get(i)

                if (item.sender !== chat.userId) {
                    eventList.updateMarkerFuture = py.callCoro(
                        "update_room_read_marker",
                        [chat.roomId, item.event_id],
                        () => { eventList.updateMarkerFuture = null },
                        () => { eventList.updateMarkerFuture = null },
                    )
                    return
                }
            }
        }
    }

    HNoticePage {
        text: qsTr("No messages to show yet")

        visible: eventList.model.count < 1
        anchors.fill: parent
    }
}
