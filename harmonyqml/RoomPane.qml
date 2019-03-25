import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

Rectangle {
    id: roomPane
    color: "gray"
    clip: true  // Avoid artifacts when resizing pane width to minimum

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TopBar {}

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            id: roomListView
            spacing: 0
            model: Backend.roomsModel
            delegate: RoomDelegate {}
            //highlight: Rectangle {color: "lightsteelblue"; radius: 5}

            section.property: "account_id"
            section.delegate: AccountDelegate {}
        }
    }
}
