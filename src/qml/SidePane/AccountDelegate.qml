import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

HTileDelegate {
    id: accountDelegate
    spacing: 0
    topPadding: model.index > 0 ? sidePane.currentSpacing / 2 : 0
    bottomPadding: topPadding
    backgroundColor: theme.sidePane.account.background
    opacity: collapsed && ! forceExpand ?
             theme.sidePane.account.collapsedOpacity : 1

    shouldBeCurrent:
        window.uiState.page == "Pages/AccountSettings/AccountSettings.qml" &&
        window.uiState.pageProperties.userId == model.data.user_id

    setCurrentTimer.running:
        ! sidePaneList.activateLimiter.running && ! sidePane.hasFocus


    Behavior on opacity { HNumberAnimation {} }


    property bool disconnecting: false
    readonly property bool forceExpand: Boolean(sidePaneList.filter)

    // Hide harmless error when a filter matches nothing
    readonly property bool collapsed: try {
        return sidePaneList.collapseAccounts[model.data.user_id] || false
    } catch (err) {}


    onActivated: if (! disconnecting) {
        pageLoader.showPage(
            "AccountSettings/AccountSettings", { "userId": model.data.user_id }
        )
    }


    function toggleCollapse() {
        window.uiState.collapseAccounts[model.data.user_id] = ! collapsed
        window.uiStateChanged()
    }


    image: HUserAvatar {
        clientUserId: model.data.user_id
        userId: model.data.user_id
        displayName: model.data.display_name
        mxc: model.data.avatar_url
    }

    title.color: theme.sidePane.account.name
    title.text: model.data.display_name || model.data.user_id
    title.font.pixelSize: theme.fontSize.big
    title.leftPadding: sidePane.currentSpacing

    HButton {
        id: addChat
        iconItem.dimension: 16
        icon.name: "add-chat"
        backgroundColor: "transparent"
        toolTip.text: qsTr("Add new chat")
        onClicked: pageLoader.showPage(
            "AddChat/AddChat", {userId: model.data.user_id},
        )

        leftPadding: theme.spacing / 2
        rightPadding: leftPadding

        visible: opacity > 0
        opacity: expand.loading ? 0 : 1

        Layout.fillHeight: true

        Behavior on opacity { HNumberAnimation {} }
    }

    HButton {
        id: expand
        loading: ! model.data.first_sync_done || ! model.data.profile_updated
        iconItem.dimension: addChat.iconItem.dimension
        icon.name: "expand"
        backgroundColor: "transparent"
        toolTip.text: collapsed ? qsTr("Expand") : qsTr("Collapse")
        onClicked: accountDelegate.toggleCollapse()

        leftPadding: theme.spacing / 2
        rightPadding: leftPadding

        visible: opacity > 0
        opacity: ! loading && accountDelegate.forceExpand ? 0 : 1

        Layout.fillHeight: true

        iconItem.transform: Rotation {
            origin.x: expand.iconItem.width / 2
            origin.y: expand.iconItem.height / 2
            angle: expand.loading ? 0 : collapsed ? 180 : 90

            Behavior on angle { HNumberAnimation {} }
        }

        Behavior on opacity { HNumberAnimation {} }
    }

    contextMenu: HMenu {
        HMenuItem {
            icon.name: "logout"
            icon.color: theme.colors.negativeBackground
            text: qsTr("Logout")
            onTriggered: Utils.makePopup(
                "Popups/LogoutPopup.qml",
                mainUI,
                { "userId": model.data.user_id },
                popup => { popup.ok.connect(() => { disconnecting = true }) },
            )
        }
    }
}
