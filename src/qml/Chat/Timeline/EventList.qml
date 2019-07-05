import QtQuick 2.7
import SortFilterProxyModel 0.2
import "../../Base"

HRectangle {
    property int space: 8

    color: HStyle.chat.roomEventList.background

    HListView {
        id: roomEventListView
        clip: true

        model: HListModel {
            sourceModel: timelines

            filters: ValueFilter {
                roleName: "roomId"
                value: chatPage.roomId
            }
        }

        delegate: EventDelegate {}

        anchors.fill: parent
        anchors.leftMargin: space
        anchors.rightMargin: space

        topMargin: space
        bottomMargin: space
        verticalLayoutDirection: ListView.BottomToTop

        // Keep x scroll pages cached, to limit images having to be
        // reloaded from network.
        cacheBuffer: height * 6

        // Declaring this as "alias" provides the on... signal
        property real yPos: visibleArea.yPosition
        property bool canLoad: true
        property int zz: 0

        onYPosChanged: {
            if (chatPage.category != "Invites" && canLoad && yPos <= 0.1) {
                zz += 1
                print(canLoad, zz)
                canLoad = false
                py.callClientCoro(
                    chatPage.userId,
                    "load_past_events",
                    [chatPage.roomId],
                    {},
                    function(more_to_load) { canLoad = more_to_load }
                )
            }
        }
    }

    HNoticePage {
        text: qsTr("Nothing to show here yet...")

        visible: roomEventListView.model.count < 1
        anchors.fill: parent
    }
}
