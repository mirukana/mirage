import QtQuick 2.7
import QtQuick.Controls 1.4 as Controls1
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "sidePane" as SidePane
import "chat" as Chat

//https://doc.qt.io/qt-5/qml-qtquick-controls-splitview.html
Controls1.SplitView {
    anchors.fill: parent

    SidePane.Root {
        Layout.minimumWidth: 36
        width: 200
    }

    StackView {
        function showRoom(userId, roomId) {
            pageStack.replace(
                "chat/Root.qml", { userId: userId, roomId: roomId }
            )
        }

        id: pageStack

        onCurrentItemChanged: currentItem.forceActiveFocus()

        initialItem: Item {  // TODO: (test, remove)
            Keys.onEnterPressed: pageStack.showRoom(
                "@test_mary:matrix.org", "!TSXGsbBbdwsdylIOJZ:matrix.org"
                //"@test_mary:matrix.org", "!TEXkdeErtVCMqClNfb:matrix.org"
            )
        }

        // Buggy
        replaceExit: null
        popExit: null
        pushExit: null
    }
}
