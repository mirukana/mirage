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
            console.log("replaced")
        }

        id: "pageStack"

        onCurrentItemChanged: currentItem.forceActiveFocus()

        initialItem: MouseArea {  // TODO: (test, remove)
            onClicked: pageStack.showRoom(
                "@test_mary:matrix.org", "!VDSsFIzQnXARSCVNxS:matrix.org"
            )
        }

        // Buggy
        replaceExit: null
        popExit: null
        pushExit: null
    }
}
