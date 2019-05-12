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

    property bool accountsLoggedIn: Backend.clients.count > 0

    HSplitView {
        id: uiSplitView
        anchors.fill: parent

        SidePane {
            visible: accountsLoggedIn
            collapsed: width < Layout.minimumWidth + normalSpacing

            function set_width() {
                width = parent.width * 0.3 < 120 ?
                        Layout.minimumWidth : Math.min(parent.width * 0.3, 300)
            }

            property int parentWidth: parent.width
            onParentWidthChanged: if (uiSplitView.canAutoSize) { set_width() }

            width: set_width()  // Initial width
            Layout.minimumWidth: HStyle.avatar.size
            Layout.maximumWidth: parent.width
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
                if (accountsLoggedIn) { initialRoomTimer.start() }
            }

            Timer {
                // TODO: remove this, debug
                id: initialRoomTimer
                interval: appWindow.reloadedTimes > 0 ? 0 : 5000
                repeat: false
                onTriggered: pageStack.showRoom(
                    "@test_mary:matrix.org",
                    "Rooms",
                    //"!TSXGsbBbdwsdylIOJZ:matrix.org"
                    "!HfNYlUkGqcWcpDQJpb:matrix.org"
                )
            }

            onCurrentItemChanged: if (currentItem) {
                currentItem.forceActiveFocus()
            }

            // Buggy
            replaceExit: null
            popExit: null
            pushExit: null
        }

        Keys.onEscapePressed: Backend.pdb()  // TODO: only if debug mode True
    }
}
