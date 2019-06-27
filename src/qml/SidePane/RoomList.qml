import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

HListView {
    property string userId: ""
    property string category: ""

    id: roomList
    spacing: accountList.spacing
    model:
        Backend.accounts.get(userId).roomCategories.get(category).sortedRooms
    delegate: RoomDelegate {}
}
