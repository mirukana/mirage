import QtQuick 2.7
import "../../Base"

HGlassRectangle {
    property bool canLoadPastEvents: true
    property int space: 8

    color: HStyle.chat.roomEventList.background

    ListView {
        id: roomEventListView
        delegate: RoomEventDelegate {}
        model: Backend.roomEvents.get(chatPage.roomId)
        clip: true

        anchors.fill: parent
        anchors.leftMargin: space
        anchors.rightMargin: space

        topMargin: space
        bottomMargin: space
        verticalLayoutDirection: ListView.BottomToTop

        // Keep x scroll pages cached, to limit images having to be
        // reloaded from network.
        cacheBuffer: height * 6

        // Declaring this "alias" provides the on... signal
        property real yPos: visibleArea.yPosition

        onYPosChanged: {
            if (chatPage.canLoadPastEvents && yPos <= 0.1) {
                Backend.loadPastEvents(chatPage.roomId)
            }
        }
    }

    HNoticePage {
        text: qsTr("Nothing to show here yet...")

        visible: roomEventListView.model.count < 1
        anchors.fill: parent
    }
}
