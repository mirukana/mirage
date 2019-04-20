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
        model: Backend.models.roomEvents.get(chatPage.roomId)

        clip: true
        topMargin: space
        bottomMargin: space
        verticalLayoutDirection: ListView.BottomToTop

        // Keep x scroll pages cached, to limit images having to be
        // reloaded from network.
        cacheBuffer: height * 6

        // Declaring this "alias" provides the on... signal
        property real yPos: visibleArea.yPosition

        onYPosChanged: {
            if (yPos <= 0.1) {
                Backend.loadPastEvents(chatPage.roomId)
            }
        }
    }
}
