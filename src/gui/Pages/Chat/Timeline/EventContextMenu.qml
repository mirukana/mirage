// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import "../../.."
import "../../../Base"
import "../../../PythonBridge"

HMenu {
    id: menu

    property HListView eventList
    property int eventIndex: -1
    property Item eventDelegate: null  // TODO: Qt 5.13: just use itemAtIndex()
    property string hoveredLink: ""

    readonly property QtObject event: eventList.model.get(eventIndex) || null

    readonly property bool isEncryptedMedia:
        event && Object.keys(JSON.parse(event.media_crypt_dict)).length > 0

    readonly property var mediaType:   // Utils.Media.<Type> or null
        event && event.media_http_url ? eventList.getMediaType(event) :
        hoveredLink ? utils.getLinkType(hoveredLink) :
        null

    function spawn(eventIndex, eventDelegate, hoveredLink="") {
        menu.eventIndex    = eventIndex
        menu.eventDelegate = eventDelegate
        menu.hoveredLink   = hoveredLink
        menu.popup()
    }

    onClosed: {
        hoveredLink = ""
        eventIndex  = -1
    }

    HMenuItem {
        icon.name: "toggle-select-message"
        text:
            event && event.id in eventList.checked ?
            qsTr("Deselect") :
            qsTr("Select")

        onTriggered: eventList.toggleCheck(eventIndex)
    }

    HMenuItem {
        visible: eventList.selectedCount >= 2
        icon.name: "deselect-all-messages"
        text: qsTr("Deselect all")
        onTriggered: eventList.checked = {}
    }

    HMenuItem {
        visible: eventIndex > 0
        icon.name: "select-until-here"
        text: qsTr("Select until here")
        onTriggered: eventList.checkFromLastToHere(eventIndex)
    }

    HMenuItem {
        icon.name: "open-externally"
        text: qsTr("Open externally")
        visible: Boolean(event && event.media_url)
        onTriggered: eventList.openMediaExternally(event)
    }

    HMenuItem {
        icon.name: "copy-local-path"
        text: qsTr("Copy local path")
        visible: Boolean(event && event.media_local_path)
        onTriggered:
            Clipboard.text =
                event.media_local_path.replace(/^file:\/\//, "")
    }

    HMenuItem {
        id: copyMedia
        icon.name: "copy-link"
        visible: menu.mediaType !== null && ! menu.isEncryptedMedia
        text:
            ! visible ?  "" :
            menu.mediaType === Utils.Media.File ? qsTr("Copy file address") :
            menu.mediaType === Utils.Media.Image ? qsTr("Copy image address") :
            menu.mediaType === Utils.Media.Video ? qsTr("Copy video address") :
            menu.mediaType === Utils.Media.Audio ? qsTr("Copy audio address") :
            qsTr("Copy link address")

        onTriggered: Clipboard.text = event.media_http_url || menu.hoveredLink
    }

    HMenuItem {
        icon.name: "copy-text"
        text:
            eventList.selectedCount ? qsTr("Copy selection") :
            event && event.media_url ? qsTr("Copy filename") :
            qsTr("Copy text")

        onTriggered: {
            if (! eventList.selectedCount){
                Clipboard.text =
                    JSON.parse(event.source).body ||
                    utils.stripHtmlTags(utils.processedEventText(event))

                return
            }

            eventList.copySelectedDelegates()
        }
    }

    HMenuItem {
        icon.name: "reply-to"
        text: qsTr("Reply")

        onTriggered: {
            chat.replyToEventId     = event.id
            chat.replyToUserId      = event.sender_id
            chat.replyToDisplayName = event.sender_name
        }
    }

    HMenuItemPopupSpawner {
        readonly property var events:
            eventList.selectedCount ?
            eventList.redactableCheckedEvents :

            event && eventList.canRedact(event) ?
            [event] :

            []

        icon.name: "remove-message"
        text: qsTr("Remove")
        enabled: properties.eventSenderAndIds.length

        popup: "Popups/RedactPopup.qml"
        properties: ({
            preferUserId: chat.userId,
            roomId: chat.roomId,
            eventSenderAndIds: events.map(ev => [ev.sender_id, ev.id]),

            onlyOwnMessageWarning:
                ! chat.roomInfo.can_redact_all &&
                events.length < eventList.selectedCount
        })
    }

    HMenuItem {
        icon.name: "debug"
        text: qsTr("Debug")
        onTriggered: mainUI.debugConsole.toggle(eventDelegate, ".j t.dict()")
    }

    HMenuItemPopupSpawner {
        icon.name: "clear-messages"
        text: qsTr("Clear messages")

        popup: "Popups/ClearMessagesPopup.qml"
        properties: ({
            userId: chat.userId,
            roomId: chat.roomId,
            preClearCallback: eventList.uncheckAll,
        })
    }
}
