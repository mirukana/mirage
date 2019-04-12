import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

ListView {
    property var for_user_id: null

    property int contentHeight: 0

    onCountChanged: {
        var children = roomList.children
        var childrenHeight = 0

        for (var i = 0; i < children.length; i++) {
            childrenHeight += children[i].height
        }

        contentHeight = childrenHeight + spacing * (children.length - 1)
    }

    id: "roomList"
    spacing: 8
    model: Backend.models.rooms.get(for_user_id)
    delegate: RoomDelegate {}
}
