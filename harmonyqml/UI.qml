import QtQuick.Controls 1.4 as Controls1
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

//https://doc.qt.io/qt-5/qml-qtquick-controls-splitview.html
Controls1.SplitView {
    anchors.fill: parent

    SidePane {
        Layout.minimumWidth: 36
        width: 200
    }

    StackView {
        function show_page(componentName) {
            pageStack.replace(componentName + ".qml")
        }
        function show_room(user_obj, room_obj) {
            pageStack.replace(
                "ChatPage.qml", { user: user_obj, room: room_obj }
            )
        }

        id: "pageStack"
        initialItem: ChatPage {
            user: Backend.accountsModel.get(0)
            room: Backend.roomsModel[Backend.accountsModel.get(0).user_id].get(0)
        }

        onCurrentItemChanged: currentItem.forceActiveFocus()

        // Buggy
        replaceExit: null
        popExit: null
        pushExit: null
    }
}
