import QtQuick.Controls 1.4 as Controls1
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

//https://doc.qt.io/qt-5/qml-qtquick-controls-splitview.html
Controls1.SplitView {
    anchors.fill: parent

    RoomPane {
        Layout.minimumWidth: 32
        width: 180
    }

    StackView {
        function show_page(componentName) {
            pageStack.replace(componentName + ".qml")
        }
        function show_room(room_obj) {
            pageStack.replace("ChatPage.qml", { room: room_obj })
        }

        id: "pageStack"
        initialItem: ChatPage { room: Backend.roomsModel.get(0) }

        onCurrentItemChanged: currentItem.forceActiveFocus()

        // Buggy
        replaceExit: null
        popExit: null
        pushExit: null
    }
}
