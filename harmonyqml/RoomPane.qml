import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

Rectangle {
    id: roomPane
    Layout.preferredWidth: 150
    Layout.fillHeight: true
    color: "gray"

    Column {
        anchors.fill: parent
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
