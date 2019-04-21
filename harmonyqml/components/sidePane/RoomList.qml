import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

ListView {
    property var forUserId: null

    property int childrenHeight: 36
    property int sectionHeight: 16 + spacing
    property int contentHeight: 0

    onCountChanged: {
        var sections = []

        for (var i = 0; i < model.count; i++) {
            var categ = model.get(i).category
            if (sections.indexOf(categ) == -1) { sections.push(categ) }
        }

        contentHeight =
            childrenHeight * model.count +
            spacing * Math.max(0, (model.count - 1)) +
            sectionHeight * sections.length
    }

    id: roomList
    spacing: 8
    model: Backend.models.rooms.get(forUserId)
    delegate: RoomDelegate {}

    section.property: "category"
    section.delegate: RoomCategoryDelegate { height: sectionHeight }
}
