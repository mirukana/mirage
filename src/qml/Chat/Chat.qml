import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"
import "Banners"
import "Timeline"
import "RoomSidePane"

HColumnLayout {
    property var roomInfo: null
    onRoomInfoChanged: if (! roomInfo) { pageStack.showPage("Default") }

    readonly property string userId: roomInfo.userId
    readonly property string category: roomInfo.category
    readonly property string roomId: roomInfo.roomId

    readonly property var senderInfo: users.getUser(userId)

    readonly property bool hasUnknownDevices: false
         //category == "Rooms" ?
         //Backend.clients.get(userId).roomHasUnknownDevices(roomId) : false

    id: chatPage
    onFocusChanged: sendBox.setFocus()

    RoomHeader {
        id: roomHeader
        displayName: roomInfo.displayName
        topic: roomInfo.topic

        Layout.fillWidth: true
        Layout.preferredHeight: theme.avatar.size
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

            TypingMembersBar {
                Layout.fillWidth: true
            }

            InviteBanner {
                visible: category == "Invites"
                inviterId: roomInfo.inviterId
            }

            //UnknownDevicesBanner {
                //visible: category == "Rooms" && hasUnknownDevices
            //}

            SendBox {
                id: sendBox
                visible: category == "Rooms" && ! hasUnknownDevices
            }

            LeftBanner {
                visible: category == "Left"
                userId: chatPage.userId
            }
        }

        RoomSidePane {
            id: roomSidePane

            activeView: roomHeader.activeButton
            property int oldWidth: width
            onActiveViewChanged:
                activeView ? restoreAnimation.start() : hideAnimation.start()

            HNumberAnimation {
                id: hideAnimation
                target: roomSidePane
                properties: "width"
                from: target.width
                to: 0

                onStarted: {
                    target.oldWidth = target.width
                    target.Layout.minimumWidth = 0
                }
            }

            HNumberAnimation {
                id: restoreAnimation
                target: roomSidePane
                properties: "width"
                from: 0
                to: target.oldWidth

                onStopped: target.Layout.minimumWidth = Qt.binding(
                    function() { return theme.avatar.size }
                )
           }

            collapsed: width < theme.avatar.size + 8

            property bool wasSnapped: false
            property int referenceWidth: roomHeader.buttonsWidth
            onReferenceWidthChanged: {
                if (chatSplitView.canAutoSize || wasSnapped) {
                    if (wasSnapped) { chatSplitView.canAutoSize = true }
                    width = referenceWidth
                }
            }

            property int currentWidth: width
            onCurrentWidthChanged: {
                if (referenceWidth != width &&
                    referenceWidth - 15 < width &&
                    width < referenceWidth + 15)
                {
                    currentWidth = referenceWidth
                    width = referenceWidth
                    wasSnapped = true
                    currentWidth = Qt.binding(
                        function() { return roomSidePane.width }
                    )
                } else {
                    wasSnapped = false
                }
            }

            width: referenceWidth // Initial width
            Layout.minimumWidth: theme.avatar.size
            Layout.maximumWidth: parent.width
        }
    }
}
