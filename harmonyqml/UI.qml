import QtQuick.Controls 1.4 as Controls1
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

Controls1.SplitView {
    anchors.fill: parent

    RoomPane {}

    StackView {
        function show_page(componentName) {
            pageStack.replace(componentName + ".qml")
        }
        function show_room(room_obj) {
            pageStack.replace("ChatPage.qml", { room: room_obj })
        }

        id: "pageStack"
        Layout.fillWidth: true
        Layout.fillHeight: true
        //initialItem: HomePage {}
        initialItem: ChatPage { room: Backend.roomsModel.get(0) }

        onCurrentItemChanged: currentItem.forceActiveFocus()

        // Buggy
        replaceExit: null
        popExit: null
        pushExit: null
    }
}
