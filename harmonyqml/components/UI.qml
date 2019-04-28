import QtQuick 2.7
import QtQuick.Controls 1.4 as Controls1
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "base" as Base
import "sidePane" as SidePane
import "chat" as Chat

Base.HImage {
    id: mainUI
    fillMode: Image.PreserveAspectCrop
    source: "../images/login_background.jpg"
    anchors.fill: parent

    property bool accountsLoggedIn: Backend.clientManager.clientCount > 0

    //https://doc.qt.io/qt-5/qml-qtquick-controls-splitview.html
    Controls1.SplitView {
        anchors.fill: parent

        SidePane.Root {
            Layout.minimumWidth: 36
            width: 200
            visible: accountsLoggedIn
        }

        StackView {
            function showPage(name, properties) {
                pageStack.replace("pages/" + name + ".qml", properties || {})
            }

            function showRoom(userId, roomId) {
                pageStack.replace(
                    "chat/Root.qml", { userId: userId, roomId: roomId }
                )
            }

            id: pageStack
            Component.onCompleted: showPage(
                accountsLoggedIn ? "Default" : "SignIn"
            )

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
