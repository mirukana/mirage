import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../base" as Base

Column {
    id: rootCol

    function mins_between(date1, date2) {
        return Math.round((((date2 - date1) % 86400000) % 3600000) / 60000)
    }

    readonly property bool isMessage: type.startsWith("RoomMessage")

    readonly property bool isUndecryptableEvent:
        type === "OlmEvent" || type === "MegolmEvent"

    readonly property string displayName:
        Backend.getUser(dict.sender).display_name

    readonly property bool isOwn:
        chatPage.user_id === dict.sender

    readonly property var previousData:
        index > 0 ? messageListView.model.get(index - 1) : null

    readonly property bool isFirstMessage: ! previousData

    readonly property bool combine:
        ! isFirstMessage &&
        previousData.isMessage === isMessage &&
        previousData.dict.sender === dict.sender &&
        mins_between(previousData.date_time, date_time) <= 5

    readonly property bool dayBreak:
        isFirstMessage ||
        previousData.date_time.getDay() != date_time.getDay()

    readonly property bool talkBreak:
        ! isFirstMessage &&
        ! dayBreak &&
        mins_between(previousData.date_time, date_time) >= 20


    property int standardSpacing: 8
    property int horizontalPadding: 7
    property int verticalPadding: 5

    width: parent.width
    topPadding:
        previousData === null ? 0 :
        talkBreak ? standardSpacing * 6 :
        combine ? standardSpacing / 2 :
        standardSpacing * 1.2

    Daybreak { visible: dayBreak }

    MessageContent { visible: isMessage }

    EventContent { visible: ! isMessage }
}
