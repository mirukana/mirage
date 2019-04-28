import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

ListView {
    property var userId: null

    property int childrenHeight: 36
    property int sectionHeight: 16 + spacing
    property int contentHeight: getContentHeight()

    function getContentHeight() {
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

    Connections {
        target: model
        onChanged: getContentHeight()
    }

    id: roomList
    spacing: 8
    model: Backend.models.rooms.get(userId)
    delegate: RoomDelegate {}

    section.property: "category"
    section.delegate: RoomCategoryDelegate { height: sectionHeight }
}
