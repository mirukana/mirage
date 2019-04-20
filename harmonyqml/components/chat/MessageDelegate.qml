import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../base" as Base
import "utils.js" as ChatJS

Column {
    id: "messageDelegate"

    function mins_between(date1, date2) {
        return Math.round((((date2 - date1) % 86400000) % 3600000) / 60000)
    }

    function is_message(type_) { return type_.startsWith("RoomMessage") }

    function get_previous_item() {
        return index < messageListView.model.count - 1 ?
                messageListView.model.get(index + 1) : null
    }

    property var previousItem: get_previous_item()
    signal reloadPreviousItem()
    onReloadPreviousItem: previousItem = get_previous_item()

    readonly property bool isMessage: is_message(type)

    readonly property bool isUndecryptableEvent:
        type === "OlmEvent" || type === "MegolmEvent"

    readonly property var displayName:
        Backend.getUserDisplayName(dict.sender)

    readonly property bool isOwn:
        chatPage.user_id === dict.sender

    readonly property bool isFirstEvent: type == "RoomCreateEvent"

    readonly property bool combine:
        previousItem &&
        ! talkBreak &&
        ! dayBreak &&
        is_message(previousItem.type) === isMessage &&
        previousItem.dict.sender === dict.sender &&
        mins_between(previousItem.date_time, date_time) <= 5

    readonly property bool dayBreak:
        isFirstEvent ||
        previousItem &&
        date_time.getDay() != previousItem.date_time.getDay()

    readonly property bool talkBreak:
        previousItem &&
        ! dayBreak &&
        mins_between(previousItem.date_time, date_time) >= 20


    property int standardSpacing: 16
    property int horizontalPadding: 7
    property int verticalPadding: 5

    ListView.onAdd: {
        var next_delegate = messageListView.contentItem.children[index]
        if (next_delegate) { next_delegate.reloadPreviousItem() }
    }

    width: parent.width

    topPadding:
        isFirstEvent ? 0 :
        talkBreak ? standardSpacing * 3 :
        combine ? standardSpacing / 4 :
        standardSpacing

    Daybreak { visible: dayBreak }

    MessageContent { visible: isMessage }

    EventContent { visible: ! isMessage }
}
