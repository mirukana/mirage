import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

Rectangle {
    property int space: 8

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.leftMargin: space
    Layout.rightMargin: space

    ListView {
        id: messageListView
        anchors.fill: parent
        model: Backend.models.messages.get(chatPage.room.room_id)
        delegate: MessageDelegate {}
        //highlight: Rectangle {color: "lightsteelblue"; radius: 5}

        clip: true
        topMargin: space
        bottomMargin: space
    }
}
