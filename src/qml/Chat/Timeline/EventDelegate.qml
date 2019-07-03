import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"

Column {
    id: roomEventDelegate

    function minsBetween(date1, date2) {
        return Math.round((((date2 - date1) % 86400000) % 3600000) / 60000)
    }

    function getPreviousItem(nth) {
        // Remember, index 0 = newest bottomest message
        nth = nth || 1
        return model.index + nth - 1 < roomEventListView.model.count - 1 ?
                roomEventListView.model.get(index + nth) : null
    }

    function isMessage(item) {
        return /^RoomMessage($|[A-Z])/.test(item.eventType)
    }

    property var previousItem: getPreviousItem()
    signal reloadPreviousItem()
    onReloadPreviousItem: previousItem = getPreviousItem()

    property var senderInfo: null
    Component.onCompleted:
        senderInfo = models.users.getUser(chatPage.userId, model.senderId)

    readonly property bool isOwn: chatPage.userId === model.senderId

    readonly property bool isFirstEvent: model.eventType == "RoomCreateEvent"

    readonly property bool combine:
        previousItem &&
        isMessage(previousItem) == isMessage(model) &&
        ! talkBreak &&
        ! dayBreak &&
        previousItem.senderId === model.senderId &&
        minsBetween(previousItem.date, model.date) <= 5

    readonly property bool dayBreak:
        isFirstEvent ||
        previousItem &&
        model.date.getDate() != previousItem.date.getDate()

    readonly property bool talkBreak:
        previousItem &&
        ! dayBreak &&
        minsBetween(previousItem.date, model.date) >= 20


    property int standardSpacing: 16
    property int horizontalPadding: 6
    property int verticalPadding: 4

    ListView.onAdd: {
        var nextDelegate = roomEventListView.contentItem.children[index]
        if (nextDelegate) { nextDelegate.reloadPreviousItem() }
    }

    width: parent.width

    topPadding:
        isFirstEvent ? 0 :
        dayBreak ? standardSpacing * 2 :
        talkBreak ? standardSpacing * 3 :
        combine ? standardSpacing / 4 :
        standardSpacing

    Loader {
        source: dayBreak ? "Daybreak.qml" : ""
        width: roomEventDelegate.width
    }

    Item { // TODO: put this in Daybreak.qml?
        visible: dayBreak
        width: parent.width
        height: topPadding
    }

    EventContent {
        anchors.right: isOwn ? parent.right : undefined
    }
}
