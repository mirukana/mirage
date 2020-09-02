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
    property int eventIndex: 0
    property Item eventDelegate: null  // TODO: Qt 5.13: just use itemAtIndex()
    property var hoveredMedia: []      // [Utils.Media.<Type>, url, title]
    property string hoveredLink: ""

    readonly property QtObject event: eventList.model.get(eventIndex)

    readonly property bool isEncryptedMedia:
        Object.keys(JSON.parse(event.media_crypt_dict)).length > 0

    function spawn(eventIndex, eventDelegate, hoveredMedia=[], hoveredUrl="") {
        menu.eventIndex    = eventIndex
        menu.eventDelegate = eventDelegate
        menu.hoveredMedia  = hoveredMedia
        menu.hoveredLink   = hoveredUrl
        menu.popup()
    }


    onClosed: {
        hoveredMedia = []
        hoveredLink  = ""
    }

    HMenuItem {
        icon.name: "toggle-select-message"
        text: event.id in eventList.checked ? qsTr("Deselect") : qsTr("Select")
        onTriggered: eventList.toggleCheck(eventIndex)
    }

    HMenuItem {
        visible: eventList.selectedCount >= 2
        icon.name: "deselect-all-messages"
        text: qsTr("Deselect all")
        onTriggered: eventList.checked = {}
    }

    HMenuItem {
        visible: eventIndex !== 0
        icon.name: "select-until-here"
        text: qsTr("Select until here")
        onTriggered: eventList.checkFromLastToHere(eventIndex)
    }

    HMenuItem {
        icon.name: "open-externally"
        text: qsTr("Open externally")
        visible: Boolean(event.media_url)
        onTriggered: eventList.openMediaExternally(event)
    }

    HMenuItem {
        icon.name: "copy-local-path"
        text: qsTr("Copy local path")
        visible: Boolean(event.media_local_path)
        onTriggered:
            Clipboard.text =
                event.media_local_path.replace(/^file:\/\//, "")
    }

    HMenuItem {
        id: copyMedia
        icon.name: "copy-link"
        text:
            menu.hoveredMedia.length === 0 ||
            menu.isEncryptedMedia ?
            "" :

            menu.hoveredMedia[0] === Utils.Media.File ?
            qsTr("Copy file address") :

            menu.hoveredMedia[0] === Utils.Media.Image ?
            qsTr("Copy image address") :

            menu.hoveredMedia[0] === Utils.Media.Video ?
            qsTr("Copy video address") :

            qsTr("Copy audio address")

        visible: Boolean(text)
        onTriggered: Clipboard.text = event.media_http_url  // FIXME
    }

    HMenuItem {
        icon.name: "copy-link"
        text: qsTr("Copy link address")
        visible: Boolean(menu.hoveredLink)
        onTriggered: Clipboard.text = menu.hoveredLink
    }

    HMenuItem {
        icon.name: "copy-text"
        text:
            eventList.selectedCount ? qsTr("Copy selection") :
            menu.hoveredMedia.length > 0 ? qsTr("Copy filename") :
            qsTr("Copy text")

        onTriggered: {
            if (! eventList.selectedCount){
                Clipboard.text = JSON.parse(event.source).body
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

            eventList.canRedact(event) ?
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
        text: qsTr("Debug this event")
        onTriggered: mainUI.debugConsole.toggle(eventDelegate, "t.json()")
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
