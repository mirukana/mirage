import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

Column {
    id: eventDelegate
    width: eventList.width

    topPadding:
        model.event_type == "RoomCreateEvent" ? 0 :
        dayBreak  ? theme.spacing * 4 :
        talkBreak ? theme.spacing * 6 :
        combine   ? theme.spacing / 2 :
        theme.spacing * 2


    // Remember timeline goes from newest message at index 0 to oldest
    property var previousItem: eventList.model.get(model.index + 1)
    property var nextItem: eventList.model.get(model.index - 1)

    property int modelIndex: model.index
    onModelIndexChanged: {
        previousItem = eventList.model.get(model.index + 1)
        nextItem     = eventList.model.get(model.index - 1)
    }

    property bool isOwn: chatPage.userId === model.sender_id
    property bool onRight: eventList.ownEventsOnRight && isOwn
    property bool combine: eventList.canCombine(previousItem, model)
    property bool talkBreak: eventList.canTalkBreak(previousItem, model)
    property bool dayBreak: eventList.canDayBreak(previousItem, model)

    readonly property bool smallAvatar:
        eventList.canCombine(model, nextItem) &&
        (model.event_type == "RoomMessageEmote" ||
         ! model.event_type.startsWith("RoomMessage"))

    readonly property bool collapseAvatar: combine
    readonly property bool hideAvatar: onRight

    readonly property bool hideNameLine:
        model.event_type == "RoomMessageEmote" ||
        ! model.event_type.startsWith("RoomMessage") ||
        onRight ||
        combine

    readonly property bool unselectableNameLine:
        hideNameLine && ! (onRight && ! combine)

    readonly property var previewLinks: model.preview_links

    property string hoveredImage: ""


    function json() {
        return JSON.stringify(
            Utils.getItem(
                modelSources[[
                    "Event", chatPage.userId, chatPage.roomId
                ]],
                "client_id",
                model.client_id
            ),
        null, 4)
    }


    Daybreak {
        visible: dayBreak
        width: eventDelegate.width
    }

    Item {
        visible: dayBreak
        width: parent.width
        height: topPadding
    }

    EventContent {
        id: eventContent
        x: onRight ? parent.width - width : 0

        Behavior on x { HNumberAnimation {} }
    }


    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: {
            contextMenu.link  = eventContent.hoveredLink
            contextMenu.image = eventDelegate.hoveredImage
            contextMenu.popup()
        }
    }

    HMenu {
        id: contextMenu

        property string link: ""
        property string image: ""

        onClosed: { link = ""; image = "" }

        HMenuItem {
            id: copyImage
            icon.name: "copy-link"
            text: qsTr("Copy image address")
            visible: Boolean(contextMenu.image)
            onTriggered: Utils.copyToClipboard(contextMenu.image)
        }

        HMenuItem {
            id: copyLink
            icon.name: "copy-link"
            text: qsTr("Copy link address")
            visible: Boolean(contextMenu.link)
            onTriggered: Utils.copyToClipboard(contextMenu.link)
        }

        HMenuItem {
            icon.name: "copy-text"
            text: qsTr("Copy text")
            visible: enabled || (! copyLink.visible && ! copyImage.visible)
            enabled: Boolean(selectableLabelContainer.joinedSelection)
            onTriggered:
                Utils.copyToClipboard(selectableLabelContainer.joinedSelection)
        }

        HMenuItem {
            icon.name: "settings"
            text: qsTr("Set as debug console target")
            visible: debugMode
            onTriggered: {
                mainUI.debugConsole.target = [eventDelegate, eventContent]
                mainUI.debugConsole.runJS("t[0].json()")
            }
        }
    }
}
