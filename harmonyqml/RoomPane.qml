import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

Rectangle {
    id: roomPane
    Layout.preferredWidth: 150
    Layout.fillHeight: true
    color: "gray"

    ListView {
        id: roomListView
        anchors.fill: parent
        model: Backend.roomsModel
        delegate: RoomDelegate {}
        //highlight: Rectangle {color: "lightsteelblue"; radius: 5}

        section.property: "account_id"
        section.delegate: AccountDelegate {}
    }
}
