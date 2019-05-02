import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.7
import "Base"
import "SidePane"

Item {
    id: mainUI

    HImage {
        id: mainUIBackground
        fillMode: Image.PreserveAspectCrop
        source: "../images/login_background.jpg"
        sourceSize.width: Screen.width
        sourceSize.height: Screen.height
        anchors.fill: parent
    }

    property bool accountsLoggedIn: Backend.clientManager.clientCount > 0

    HSplitView {
        anchors.fill: parent

        SidePane {
            property int parentWidth: parent.width
            onParentWidthChanged: width = Math.min(parent.width * 0.3, 300)

            Layout.minimumWidth: 36
            Layout.maximumWidth: parent.width
            visible: accountsLoggedIn
        }

        StackView {
            id: pageStack

            property bool initialPageSet: false

            function showPage(name, properties) {
                pageStack.replace("Pages/" + name + ".qml", properties || {})
            }

            function showRoom(userId, category, roomId) {
                pageStack.replace(
                    "Chat/Chat.qml",
                    { userId: userId, category: category, roomId: roomId }
                )
            }

            Component.onCompleted: {
                if (pageStack.initialPageSet) { return }
                pageStack.initialPageSet = true
                showPage(accountsLoggedIn ? "Default" : "SignIn")
            }

            onCurrentItemChanged: if (currentItem) {
                currentItem.forceActiveFocus()
            }

            // Buggy
            replaceExit: null
            popExit: null
            pushExit: null
        }
    }
}
