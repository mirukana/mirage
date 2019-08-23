import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HTileDelegate {
    id: accountDelegate
    spacing: 0
    topPadding: model.index > 0 ? sidePane.currentSpacing / 2 : 0
    bottomPadding: topPadding
    backgroundColor: theme.sidePane.account.background
    opacity: collapsed && ! forceExpand ?
             theme.sidePane.account.collapsedOpacity : 1

    shouldBeCurrent:
        window.uiState.page == "Pages/EditAccount/EditAccount.qml" &&
        window.uiState.pageProperties.userId == model.data.user_id

    setCurrentTimer.running: ! accountRoomList.activateLimiter.running


    Behavior on opacity { HNumberAnimation {} }


    property bool disconnecting: false
    readonly property bool forceExpand: Boolean(accountRoomList.filter)

    // Hide harmless error when a filter matches nothing
    readonly property bool collapsed: try {
        return accountRoomList.collapseAccounts[model.data.user_id] || false
    } catch (err) {}


    onActivated: if (! disconnecting) {
        pageLoader.showPage(
            "EditAccount/EditAccount", { "userId": model.data.user_id }
        )
    }


    function toggleCollapse() {
        window.uiState.collapseAccounts[model.data.user_id] = ! collapsed
        window.uiStateChanged()
    }


    image: HUserAvatar {
        userId: model.data.user_id
        displayName: model.data.display_name
        avatarUrl: model.data.avatar_url
    }

    title.color: theme.sidePane.account.name
    title.text: model.data.display_name || model.data.user_id
    title.font.pixelSize: theme.fontSize.big
    title.leftPadding: sidePane.currentSpacing

    HButton {
        id: expand
        icon.name: "expand"
        backgroundColor: "transparent"
        padding: sidePane.currentSpacing / 1.5
        rightPadding: leftPadding
        toolTip.text: collapsed ? qsTr("Expand") : qsTr("Collapse")
        onClicked: accountDelegate.toggleCollapse()

        visible: opacity > 0
        opacity: accountDelegate.forceExpand ? 0 : 1

        iconItem.transform: Rotation {
            origin.x: expand.iconItem.dimension / 2
            origin.y: expand.iconItem.dimension / 2

            angle: collapsed ? 180 : 90
            Behavior on angle { HNumberAnimation {} }
        }

        Behavior on opacity { HNumberAnimation {} }
    }

    contextMenu: HMenu {
        HMenuItem {
            icon.name: "logout"
            text: qsTr("Logout")
            onTriggered: {
                disconnecting = true

                let page   = window.uiState.page
                let userId = model.data.user_id

                if ((modelSources["Account"] || []).length < 2) {
                    pageLoader.showPage("SignIn")
                }
                else if ((page == "Pages/EditAccount/EditAccount.qml" ||
                     page == "Chat/Chat.qml") &&
                     window.uiState.pageProperties.userId == userId)
                {
                    pageLoader.showPage("Default")
                }

                py.callCoro("logout_client", [userId])
            }
        }
    }
}
