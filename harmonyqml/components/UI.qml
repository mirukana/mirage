import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "base" as Base
import "sidePane" as SidePane
import "chat" as Chat

Item {
    id: mainUI

    Base.HImage {
        id: mainUIBackground
        fillMode: Image.PreserveAspectCrop
        source: "../images/login_background.jpg"
        anchors.fill: parent
    }

    property bool accountsLoggedIn: Backend.clientManager.clientCount > 0

    Base.HSplitView {
        anchors.fill: parent

        SidePane.Root {
            Layout.minimumWidth: 36
            width: 200
            visible: accountsLoggedIn
        }

        StackView {
            id: pageStack

            property bool initialPageSet: false

            function showPage(name, properties) {
                pageStack.replace("pages/" + name + ".qml", properties || {})
            }

            function showRoom(userId, roomId) {
                pageStack.replace(
                    "chat/Root.qml", { userId: userId, roomId: roomId }
                )
            }

            Component.onCompleted: {
                if (initialPageSet) { return }
                initialPageSet = true
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
