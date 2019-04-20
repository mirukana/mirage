import QtQuick.Controls 1.4 as Controls1
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "side_pane" as SidePane
import "chat" as Chat

//https://doc.qt.io/qt-5/qml-qtquick-controls-splitview.html
Controls1.SplitView {
    anchors.fill: parent

    SidePane.Root {
        Layout.minimumWidth: 36
        width: 200
    }

    StackView {
        function show_page(componentName) {
            pageStack.replace(componentName + ".qml")
        }
        function show_room(user_id, room_obj) {
            pageStack.replace(
                "chat/Root.qml", { user_id: user_id, room: room_obj }
            )
            console.log("replaced")
        }

        id: "pageStack"

        onCurrentItemChanged: currentItem.forceActiveFocus()

        // Buggy
        replaceExit: null
        popExit: null
        pushExit: null
    }
}
