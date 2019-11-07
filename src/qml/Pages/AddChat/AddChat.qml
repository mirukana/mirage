import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HPage {
    id: addChatPage
    onFocusChanged: createRoom.forceActiveFocus()


    property string userId


    HColumnLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: Layout.maximumWidth
        Layout.maximumWidth:
            Math.max(tabBar.contentWidth, swipeView.contentWidth)

        TabBar {
            id: tabBar
            position: TabBar.Header
            currentIndex: 2

            Layout.fillWidth: true

            Repeater {
                model: [
                    qsTr("Find someone"),
                    qsTr("Join room"),
                    qsTr("Create room"),
                ]

                HTabButton {
                    text: modelData
                }
            }
        }


        SwipeView {
            id: swipeView
            clip: true
            currentIndex: tabBar.currentIndex

            Layout.fillWidth: true

            Item {}
            Item {}

            CreateRoom {
                id: createRoom
            }
        }
    }
}
