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
        delegate: MessageDelegate {}
        model: Backend.models.roomEvents.get(chatPage.room.room_id)
        //highlight: Rectangle {color: "lightsteelblue"; radius: 5}

        clip: true
        topMargin: space
        bottomMargin: space
        verticalLayoutDirection: ListView.BottomToTop

        // Keep x scroll pages cached, to limit images having to be
        // reloaded from network.
        cacheBuffer: height * 6

        function goToEnd() {
            messageListView.positionViewAtEnd()
            //messageListView.flick(0, -messageListView.bottomMargin * 100)
        }

        //Connections {
            //target: messageListView.model
            //onChanged: goToEnd()
        //}
    }
}
