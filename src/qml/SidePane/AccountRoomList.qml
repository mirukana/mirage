import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HListView {
    id: accountRoomList

    // property bool forceExpand: paneToolBar.roomFilter && roomList.model.count
    property bool forceExpand: false

    model: HListModel {
        keyField: "id"
        source: window.sidePaneModelSource
    }

    delegate: Loader {
        width: accountRoomList.width
        source: "Delegate" +
                (model.type == "Account" ? "Account.qml" : "Room.qml")
    }
}
