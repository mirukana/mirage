import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

HListView {
    id: accountRoomList


    readonly property var originSource: window.sidePaneModelSource
    readonly property var collapseAccounts: window.uiState.collapseAccounts
    readonly property string filter: paneToolBar.roomFilter

    onOriginSourceChanged: Qt.callLater(filterSource)
    onFilterChanged: Qt.callLater(filterSource)
    onCollapseAccountsChanged: Qt.callLater(filterSource)


    function filterSource() {
        let show = []

        // Hide a harmless error when activating a DelegateRoom
        try { window.sidePaneModelSource } catch (err) { return }

        for (let i = 0;  i < window.sidePaneModelSource.length; i++) {
            let item = window.sidePaneModelSource[i]

            if (item.type == "Account" ||
                (filter ?
                 Utils.filterMatches(filter, item.data.filter_string) :
                 ! window.uiState.collapseAccounts[item.user_id]))
            {
                if (filter && show.length && item.type == "Account" &&
                    show[show.length - 1].type == "Account" &&
                    ! Utils.filterMatches(
                        filter, show[show.length - 1].data.filter_string)
                ) {
                    // If current and previous items are both accounts,
                    // that means the previous account had no matching rooms.
                    show.pop()
                }

                show.push(item)
            }
        }

        // If last item is an account, that account had no matching rooms.
        if (show.length && show[show.length - 1].type == "Account") show.pop()

        model.source = show
    }

    function previous() {
        accountRoomList.decrementCurrentIndex()
        accountRoomList.currentItem.item.activate()
    }

    function next() {
        accountRoomList.incrementCurrentIndex()
        accountRoomList.currentItem.item.activate()
    }


    model: HListModel {
        keyField: "id"
        source: originSource
    }

    delegate: Loader {
        width: accountRoomList.width
        source: "Delegate" +
                (model.type == "Account" ? "Account.qml" : "Room.qml")
    }
}
