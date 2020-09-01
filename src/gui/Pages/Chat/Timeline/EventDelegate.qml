// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import "../../.."
import "../../../Base"
import "../../../PythonBridge"

HColumnLayout {
    id: eventDelegate

    property var hoveredMediaTypeUrl: []  // [] or [mediaType, url, title]

    property var fetchProfilesFuture: null

    // Remember timeline goes from newest message at index 0 to oldest
    readonly property var previousModel: eventList.model.get(model.index + 1)
    readonly property var nextModel: eventList.model.get(model.index - 1)
    readonly property QtObject currentModel: model

    readonly property bool compact: window.settings.compactMode
    readonly property bool checked: model.id in eventList.checked
    readonly property bool isOwn: chat.userId === model.sender_id
    readonly property bool isRedacted: model.event_type === "RedactedEvent"
    readonly property bool onRight: ! eventList.ownEventsOnLeft && isOwn
    readonly property bool combine: eventList.canCombine(previousModel, model)
    readonly property bool talkBreak:
        eventList.canTalkBreak(previousModel, model)
    readonly property bool dayBreak:
        eventList.canDayBreak(previousModel, model)

    readonly property bool hideNameLine:
        model.event_type === "RoomMessageEmote" ||
        ! (
            model.event_type.startsWith("RoomMessage") ||
            model.event_type.startsWith("RoomEncrypted")
        ) ||
        onRight ||
        combine

    readonly property int cursorShape:
        eventContent.hoveredLink || hoveredMediaTypeUrl.length === 3 ?
        Qt.PointingHandCursor :

        eventContent.hoveredSelectable ? Qt.IBeamCursor :

        Qt.ArrowCursor

    readonly property int separationSpacing:
            dayBreak  ? theme.spacing * 4 :
            talkBreak ? theme.spacing * 6 :
            combine   ? theme.spacing / (compact ? 4 : 2) :
            theme.spacing * (compact ? 1 : 2)

    readonly property alias eventContent: eventContent

    function json() {
        let event    = ModelStore.get(chat.userId, chat.roomId, "events")
                                 .get(model.index)
        event        = JSON.parse(JSON.stringify(event))
        event.source = JSON.parse(event.source)
        return JSON.stringify(event, null, 4)
    }

    function openContextMenu() {
        contextMenu.media = eventDelegate.hoveredMediaTypeUrl
        contextMenu.link  = eventContent.hoveredLink
        contextMenu.popup()
    }

    function toggleChecked() {
        eventList.toggleCheck(model.index)
    }


    width: eventList.width - eventList.leftMargin - eventList.rightMargin

    // Needed because of eventList's MouseArea which steals the
    // HSelectableLabel's MouseArea hover events
    onCursorShapeChanged: eventList.cursorShape = cursorShape

    Component.onCompleted: if (model.fetch_profile)
        fetchProfilesFuture = py.callClientCoro(
            chat.userId,
            "get_event_profiles",
            [chat.roomId, model.id],
            () => { fetchProfilesFuture = null }
        )

    Component.onDestruction:
        if (fetchProfilesFuture) fetchProfilesFuture.cancel()

    ListView.onRemove: eventList.uncheck(model.id)

    Item {
        Layout.fillWidth: true
        visible: model.event_type !== "RoomCreateEvent"
        Layout.preferredHeight: separationSpacing
    }

    Daybreak {
        visible: dayBreak

        Layout.fillWidth: true
        Layout.minimumWidth: parent.width
        Layout.bottomMargin: separationSpacing
    }

    EventContent {
        id: eventContent

        Layout.fillWidth: true

        Behavior on x { HNumberAnimation {} }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        acceptedModifiers: Qt.NoModifier
        onTapped: toggleChecked()
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        acceptedModifiers: Qt.ShiftModifier
        onTapped: eventList.checkFromLastToHere(model.index)
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Pen
        onTapped: openContextMenu()
    }

    TapHandler {
        acceptedPointerTypes: PointerDevice.Finger | PointerDevice.Pen
        onLongPressed: openContextMenu()
    }

    HMenu {
        id: contextMenu

        property var media: []
        property string link: ""

        readonly property bool isEncryptedMedia:
            Object.keys(JSON.parse(model.media_crypt_dict)).length > 0

        onClosed: {
            media = []
            link = ""
        }

        HMenuItem {
            icon.name: "toggle-select-message"
            text: eventDelegate.checked ? qsTr("Deselect") : qsTr("Select")
            onTriggered: eventDelegate.toggleChecked()
        }

        HMenuItem {
            visible: eventList.selectedCount >= 2
            icon.name: "deselect-all-messages"
            text: qsTr("Deselect all")
            onTriggered: eventList.checked = {}
        }

        HMenuItem {
            visible: model.index !== 0
            icon.name: "select-until-here"
            text: qsTr("Select until here")
            onTriggered: eventList.checkFromLastToHere(model.index)
        }

        HMenuItem {
            icon.name: "open-externally"
            text: qsTr("Open externally")
            visible: Boolean(model.media_url)
            onTriggered: eventList.openMediaExternally(model)
        }

        HMenuItem {
            icon.name: "copy-local-path"
            text: qsTr("Copy local path")
            visible: Boolean(model.media_local_path)
            onTriggered:
                Clipboard.text =
                    model.media_local_path.replace(/^file:\/\//, "")
        }

        HMenuItem {
            id: copyMedia
            icon.name: "copy-link"
            text:
                contextMenu.media.length === 0 ||
                contextMenu.isEncryptedMedia ?
                "" :

                contextMenu.media[0] === Utils.Media.File ?
                qsTr("Copy file address") :

                contextMenu.media[0] === Utils.Media.Image ?
                qsTr("Copy image address") :

                contextMenu.media[0] === Utils.Media.Video ?
                qsTr("Copy video address") :

                qsTr("Copy audio address")

            visible: Boolean(text)
            onTriggered: Clipboard.text = model.media_http_url
        }

        HMenuItem {
            icon.name: "copy-link"
            text: qsTr("Copy link address")
            visible: Boolean(contextMenu.link)
            onTriggered: Clipboard.text = contextMenu.link
        }

        HMenuItem {
            icon.name: "copy-text"
            text:
                eventList.selectedCount ? qsTr("Copy selection") :
                contextMenu.media.length > 0 ? qsTr("Copy filename") :
                qsTr("Copy text")

            onTriggered: {
                if (! eventList.selectedCount){
                    Clipboard.text = JSON.parse(model.source).body
                    return
                }

                eventList.copySelectedDelegates()
            }
        }

        HMenuItem {
            icon.name: "reply-to"
            text: qsTr("Reply")

            onTriggered: {
                chat.replyToEventId     = model.id
                chat.replyToUserId      = model.sender_id
                chat.replyToDisplayName = model.sender_name
            }
        }

        HMenuItemPopupSpawner {
            readonly property var events: {
                eventList.selectedCount ?
                eventList.redactableCheckedEvents :

                eventList.canRedact(currentModel) ?
                [model] :

                []
            }

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
            onTriggered:
                mainUI.debugConsole.toggle(eventContent, "t.parent.json()")
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
}
