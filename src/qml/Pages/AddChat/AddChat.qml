import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HPage {
    onFocusChanged: createRoom.forceActiveFocus()

    HColumnLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: Layout.maximumWidth
        Layout.maximumWidth:
            Math.max(tabBar.implicitWidth, swipeView.contentWidth)

        TabBar {
            id: tabBar
            position: TabBar.Header
            currentIndex: 1

            Layout.fillWidth: true

            Repeater {
                model: [
                    qsTr("Find someone"),
                    qsTr("Create room"),
                    qsTr("Join room"),
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

            CreateRoom {
                id: createRoom
            }

            Item {}
        }
    }
}
