import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

Column {
    id: eventDelegate

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

    width: eventList.width

    topPadding:
        model.event_type == "RoomCreateEvent" ? 0 :
        dayBreak  ? theme.spacing * 4 :
        talkBreak ? theme.spacing * 6 :
        combine   ? theme.spacing / 2 :
        theme.spacing * 2


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
            contextMenu.link = eventContent.hoveredLink
            contextMenu.popup()
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onLongPressed: {
            contextMenu.link = eventContent.hoveredLink
            contextMenu.popup()
        }
    }

    HMenu {
        id: contextMenu

        property string link: ""

        onClosed: link = ""

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
            visible: enabled || ! copyLink.visible
            enabled: Boolean(selectableLabelContainer.joinedSelection)
            onTriggered:
                Utils.copyToClipboard(selectableLabelContainer.joinedSelection)
        }
    }
}
