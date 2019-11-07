import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HPage {
    onFocusChanged: createRoom.forceActiveFocus()

    HBox {
        id: rootBox
        multiplyWidth: 1.11
        multiplyHorizontalSpacing: 0
        multiplyVerticalSpacing: 0
        Layout.alignment: Qt.AlignCenter

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

                TabButton {
                    text: modelData
                }
            }
        }


        SwipeView {
            clip: true
            currentIndex: tabBar.currentIndex

            Layout.fillWidth: true

            Item {}

            CreateRoom {
                id: createRoom
                color: "transparent"
            }

            Item {}
        }
    }
}
