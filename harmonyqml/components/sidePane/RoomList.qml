import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

ListView {
    property var forUserId: null

    property int childrenHeight: 36
    property int contentHeight: 0

    onCountChanged: {
        contentHeight = childrenHeight * model.count +
                        spacing * (model.count - 1)
    }

    id: roomList
    spacing: 8
    model: Backend.models.rooms.get(forUserId)
    delegate: RoomDelegate {}

    section.property: "category"
    section.delegate: RoomCategoryDelegate {}
}
