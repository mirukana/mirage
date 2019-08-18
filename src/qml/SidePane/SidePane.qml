import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

HRectangle {
    id: sidePane
    clip: true  // Avoid artifacts when collapsed
    opacity: mainUI.accountsPresent && ! reduce ? 1 : 0
    visible: opacity > 0

    color: theme.sidePane.background

    property alias accountList: accountList
    property alias paneToolBar: paneToolBar

    property real autoWidthRatio: theme.sidePane.autoWidthRatio
    property bool manuallyResizing: false
    property bool manuallyResized: false
    property int manualWidth: 0
    property bool animateWidth: true

    Component.onCompleted: {
        if (window.uiState.sidePaneManualWidth) {
            manualWidth     = window.uiState.sidePaneManualWidth
            manuallyResized = true
        }
    }

    onManualWidthChanged: {
        window.uiState.sidePaneManualWidth = manualWidth
        window.uiStateChanged()
    }

    property int maximumCalculatedWidth: Math.min(
        manuallyResized ? manualWidth : theme.sidePane.maximumAutoWidth,
        window.width - theme.minimumSupportedWidthPlusSpacing
    )

    property int parentWidth: parent.width
    // Needed for SplitView since it breaks the binding when user manual sizes
    onParentWidthChanged: width = Qt.binding(() => implicitWidth)


    property int calculatedWidth: Math.min(
        manuallyResized ? manualWidth : parentWidth * autoWidthRatio,
        maximumCalculatedWidth
    )

    property bool collapse:
        (manuallyResizing ? width : calculatedWidth) <
        (manuallyResized ?
         (theme.sidePane.collapsedWidth + theme.spacing * 2) :
         theme.sidePane.autoCollapseBelowWidth)

    property bool reduce:
        window.width < theme.sidePane.autoReduceBelowWindowWidth

    property int implicitWidth:
        reduce   ? 0 :
        collapse ? theme.sidePane.collapsedWidth :
        calculatedWidth

    property int currentSpacing:
        width <= theme.sidePane.collapsedWidth + theme.spacing * 2 ?
        0 : theme.spacing

    Behavior on currentSpacing { HNumberAnimation {} }
    Behavior on implicitWidth  {
        HNumberAnimation { factor: animateWidth ? 1 : 0 }
    }


    function _getRoomModelSource(accountUserId) {
        return Utils.filterModelSource(
            modelSources[["Room", accountUserId]] || [],
            paneToolBar.roomFilter,
        )
    }

    function _activateNextAccount(i) {
        let nextIndex = i + 1 > accountList.model.count - 1 ? 0 : i + 1
        if (nextIndex == i) return

        pageStack.showPage(
            "EditAccount/EditAccount",
            {userId: accountList.model.get(nextIndex).user_id}
        )

        accountList.currentIndex = nextIndex
    }

    function activateNext() {
        if (accountList.model.count < 1) return

        for (let i = 0;  i < accountList.model.count; i++) {
            let account = accountList.model.get(i)

            if (window.uiState.page == "Pages/EditAccount/EditAccount.qml" &&
                window.uiState.pageProperties.userId == account.user_id)
            {
                let room = _getRoomModelSource(account.user_id)[0]

                if (room) { pageStack.showRoom(account.user_id, room.room_id) }
                else      { _activateNextAccount(i) }
                return
            }

            if (window.uiState.page == "Chat/Chat.qml" &&
                window.uiState.pageProperties.userId == account.user_id)
            {
                let rooms = _getRoomModelSource(account.user_id)

                if (! rooms) { _activateNextAccount(i); return }

                for (let ri = 0; ri < rooms.length; ri++) {
                    let room = rooms[ri]

                    if (room.room_id != window.uiState.pageProperties.roomId) {
                        continue
                    }

                    if (ri + 1 > rooms.length -1) {
                        _activateNextAccount(i)
                        return
                    }

                    pageStack.showRoom(account.user_id, rooms[ri + 1].room_id)

                    let currentRoomItem =
                        accountList.itemAtIndex(i).roomList.itemAtIndex(ri)

                    print(currentRoomItem.visible)

                    return
                }
            }
        }
    }


    HColumnLayout {
        anchors.fill: parent

        AccountList {
            id: accountList
            Layout.fillWidth: true
            Layout.fillHeight: true

            spacing: currentSpacing
            bottomMargin: currentSpacing
        }

        PaneToolBar {
            id: paneToolBar
        }
    }
}
