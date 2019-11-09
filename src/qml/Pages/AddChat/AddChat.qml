import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HPage {
    id: addChatPage
    onFocusChanged: findSomeone.forceActiveFocus()


    property string userId

    readonly property var account:
        Utils.getItem(modelSources["Account"] || [], "user_id", userId)


    HColumnLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: Layout.maximumWidth
        Layout.maximumWidth: Math.min(
            parent.width,
            Math.max(tabBar.contentWidth, swipeView.contentWidth),
        )

        HTabBar {
            id: tabBar
            currentIndex: 0

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
            interactive: false

            Layout.fillWidth: true

            FindSomeone { id: findSomeone }
            JoinRoom {}
            CreateRoom {}
        }
    }
}
