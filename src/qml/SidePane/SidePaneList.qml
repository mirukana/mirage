import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

HListView {
    id: sidePaneList


    readonly property var originSource: window.sidePaneModelSource
    readonly property var collapseAccounts: window.uiState.collapseAccounts
    readonly property string filter: toolbar.roomFilter
    readonly property alias activateLimiter: activateLimiter

    onOriginSourceChanged: filterLimiter.restart()
    onFilterChanged: filterLimiter.restart()
    onCollapseAccountsChanged: filterLimiter.restart()


    function filterSource() {
        let show = []

        // Hide a harmless error when activating a RoomDelegate
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
                    // If filter active, current and previous items are
                    // both accounts and previous account doesn't match filter,
                    // that means the previous account had no matching rooms.
                    show.pop()
                }

                show.push(item)
            }
        }

        let last = show[show.length - 1]
        if (show.length && filter && last.type == "Account" &&
            ! Utils.filterMatches(filter, last.data.filter_string))
        {
            // If filter active, last item is an account and last item
            // doesn't match filter, that account had no matching rooms.
            show.pop()
        }

        model.source = show
    }

    function previous(activate=true) {
        decrementCurrentIndex()
        if (activate) activateLimiter.restart()
    }

    function next(activate=true) {
        incrementCurrentIndex()
        if (activate) activateLimiter.restart()
    }

    function activate() {
        currentItem.item.activated()
    }

    function toggleCollapseAccount() {
        if (! currentItem || filter) return

        if (currentItem.item.delegateModel.type == "Account") {
            currentItem.item.toggleCollapse()
            return
        }

        for (let i = 0;  i < model.source.length; i++) {
            let item = model.source[i]

            if (item.type == "Account" && item.user_id ==
                currentItem.item.delegateModel.user_id)
            {
                currentIndex = i
                currentItem.item.toggleCollapse()
                activate()
            }
        }
    }


    model: HListModel {
        keyField: "id"
        source: originSource
    }

    delegate: Loader {
        width: sidePaneList.width
        Component.onCompleted: setSource(
            model.type == "Account" ?
            "AccountDelegate.qml" : "RoomDelegate.qml",
            {view: sidePaneList}
        )
    }


    Timer {
        id: filterLimiter
        interval: 16
        onTriggered: filterSource()
    }

    Timer {
        id: activateLimiter
        interval: 300
        onTriggered: activate()
    }
}
