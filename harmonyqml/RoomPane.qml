import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

Rectangle {
    id: roomPane
    width: 180
    Layout.minimumWidth: 48
    Layout.fillHeight: true
    color: "gray"
    clip: true  // Avoid artifacts when resizing pane width to minimum

    Column {
        x: parent.x
        y: parent.y - 48 / 2
        width: parent.width
        height: parent.height + 48 / 2
        ListView {
            width: parent.width
            height: parent.height - actionBar.height
            id: roomListView
            model: Backend.roomsModel
            delegate: RoomDelegate {}
            //highlight: Rectangle {color: "lightsteelblue"; radius: 5}

            section.property: "account_id"
            section.delegate: AccountDelegate {}
        }

        ActionBar { id: "actionBar" }
    }
}
