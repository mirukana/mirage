import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"
import "Banners"
import "Timeline"
import "RoomSidePane"

HColumnLayout {
    property string userId: ""
    property string category: ""
    property string roomId: ""

    readonly property var roomInfo: rooms.getWhere(
        {"userId": userId, "roomId": roomId, "category": category}, 1
    )[0]

    readonly property var sender:
        users.getWhere({"userId": userId}, 1)[0]

    readonly property bool hasUnknownDevices: false
         //category == "Rooms" ?
         //Backend.clients.get(userId).roomHasUnknownDevices(roomId) : false

    id: chatPage
    onFocusChanged: sendBox.setFocus()

   //Component.onCompleted: Backend.signals.roomCategoryChanged.connect(
        //function(forUserId, forRoomId, previous, now) {
            //if (chatPage && forUserId == userId && forRoomId == roomId) {
                //chatPage.category = now
            //}
        //}
    //)

    RoomHeader {
        id: roomHeader
        displayName: roomInfo.displayName
        topic: roomInfo.topic

        Layout.fillWidth: true
        Layout.preferredHeight: HStyle.avatar.size
    }


    HSplitView {
        id: chatSplitView
        Layout.fillWidth: true
        Layout.fillHeight: true

        HColumnLayout {
            Layout.fillWidth: true

            EventList {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            TypingMembersBar {}

            InviteBanner {
                visible: category === "Invites"
                inviterId: roomInfo.inviterId
            }

            //UnknownDevicesBanner {
                //visible: category == "Rooms" && hasUnknownDevices
            //}

            SendBox {
                id: sendBox
                visible: category == "Rooms" && ! hasUnknownDevices
            }

            //LeftBanner {
                //visible: category === "Left"
                //leftEvent: roomInfo.leftEvent
            //}
        //}

//        RoomSidePane {
            //id: roomSidePane

            //activeView: roomHeader.activeButton
            //property int oldWidth: width
            //onActiveViewChanged:
                //activeView ? restoreAnimation.start() : hideAnimation.start()

            //NumberAnimation {
                //id: hideAnimation
                //target: roomSidePane
                //properties: "width"
                //duration: HStyle.animationDuration
                //from: target.width
                //to: 0

                //onStarted: {
                    //target.oldWidth = target.width
                    //target.Layout.minimumWidth = 0
                //}
            //}

            //NumberAnimation {
                //id: restoreAnimation
                //target: roomSidePane
                //properties: "width"
                //duration: HStyle.animationDuration
                //from: 0
                //to: target.oldWidth

                //onStopped: target.Layout.minimumWidth = Qt.binding(
                    //function() { return HStyle.avatar.size }
                //)
           //}

            //collapsed: width < HStyle.avatar.size + 8

            //property bool wasSnapped: false
            //property int referenceWidth: roomHeader.buttonsWidth
            //onReferenceWidthChanged: {
                //if (chatSplitView.canAutoSize || wasSnapped) {
                    //if (wasSnapped) { chatSplitView.canAutoSize = true }
                    //width = referenceWidth
                //}
            //}

            //property int currentWidth: width
            //onCurrentWidthChanged: {
                //if (referenceWidth != width &&
                    //referenceWidth - 15 < width &&
                    //width < referenceWidth + 15)
                //{
                    //currentWidth = referenceWidth
                    //width = referenceWidth
                    //wasSnapped = true
                    //currentWidth = Qt.binding(
                        //function() { return roomSidePane.width }
                    //)
                //} else {
                    //wasSnapped = false
                //}
            //}

            //width: referenceWidth // Initial width
            //Layout.minimumWidth: HStyle.avatar.size
            //Layout.maximumWidth: parent.width
        //}
        }
    }
}
