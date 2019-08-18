import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

Column {
    id: accountDelegate
    width: parent.width
    spacing: theme.spacing / 2

    opacity:
        paneToolBar.roomFilter && roomList.model.count < 1 ? 0.3 : 1
    Behavior on opacity { HNumberAnimation {} }

    property alias roomList: roomList

    property bool forceExpand: paneToolBar.roomFilter && roomList.model.count
    property bool expanded: true
    readonly property var modelItem: model

    readonly property bool isCurrent:
        window.uiState.page == "Pages/EditAccount/EditAccount.qml" &&
        window.uiState.pageProperties.userId == model.user_id

    Component.onCompleted:
        expanded = ! window.uiState.collapseAccounts[model.user_id]

    onExpandedChanged: {
        window.uiState.collapseAccounts[model.user_id] = ! expanded
        window.uiStateChanged()
    }

    function activate() {
        pageStack.showPage(
            "EditAccount/EditAccount", { "userId": model.user_id }
        )
    }

    HInteractiveRectangle {
        id: rectangle
        width: parent.width
        height: childrenRect.height
        color: theme.sidePane.account.background

        checked: accountDelegate.isCurrent

        TapHandler { onTapped: accountDelegate.activate() }

        HRowLayout {
            id: row
            width: parent.width

            HUserAvatar {
                id: avatar
                userId: model.user_id
                displayName: model.display_name
                avatarUrl: model.avatar_url
            }

            HLabel {
                id: accountLabel
                color: theme.sidePane.account.name
                text: model.display_name || model.user_id
                font.pixelSize: theme.fontSize.big
                elide: HLabel.ElideRight
                leftPadding: sidePane.currentSpacing
                rightPadding: leftPadding

                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            ExpandButton {
                id: expandButton
                opacity: paneToolBar.roomFilter ? 0 : 1
                expandableItem: accountDelegate
                Layout.preferredHeight: row.height
            }
        }
    }

    RoomList {
        id: roomList
        visible: height > 0
        width: parent.width
        height:
            childrenRect.height *
            (accountDelegate.expanded || accountDelegate.forceExpand ? 1 : 0)
        clip: heightAnimation.running

        userId: modelItem.user_id

        Behavior on height { HNumberAnimation { id: heightAnimation } }
    }
}
