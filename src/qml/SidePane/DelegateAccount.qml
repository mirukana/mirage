import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HInteractiveRectangle {
    id: accountDelegate
    color: theme.sidePane.account.background
    // checked: isCurrent
    height: row.height


    readonly property var delegateModel: model

    readonly property bool isCurrent:
        window.uiState.page == "Pages/EditAccount/EditAccount.qml" &&
        window.uiState.pageProperties.userId == model.data.user_id

    readonly property bool forceExpand:
        Boolean(accountRoomList.filter)

    // Hide harmless error when a filter matches nothing
    readonly property bool collapsed: try {
        return accountRoomList.collapseAccounts[model.data.user_id] || false
    } catch (err) {}


    onIsCurrentChanged: if (isCurrent) beHighlighted()


    function beHighlighted() {
        accountRoomList.currentIndex = model.index
    }

    function toggleCollapse() {
        window.uiState.collapseAccounts[model.data.user_id] = ! collapsed
        window.uiStateChanged()
    }

    function activate() {
        pageLoader.showPage(
            "EditAccount/EditAccount", { "userId": model.data.user_id }
        )
    }


    // Component.onCompleted won't work for this
    Timer {
        interval: 100
        repeat: true
        running: accountRoomList.currentIndex == -1
        onTriggered: if (isCurrent) beHighlighted()
    }

    TapHandler { onTapped: accountDelegate.activate() }

    HRowLayout {
        id: row
        width: parent.width

        HUserAvatar {
            id: avatar
            userId: model.data.user_id
            displayName: model.data.display_name
            avatarUrl: model.data.avatar_url

            opacity: collapsed && ! forceExpand ?
                     theme.sidePane.account.collapsedOpacity : 1
            Behavior on opacity { HNumberAnimation {} }

            Layout.topMargin: model.index > 0 ? sidePane.currentSpacing / 2 : 0
            Layout.bottomMargin: Layout.topMargin
        }

        HLabel {
            id: accountLabel
            color: theme.sidePane.account.name
            text: model.data.display_name || model.data.user_id
            font.pixelSize: theme.fontSize.big
            elide: HLabel.ElideRight

            leftPadding: sidePane.currentSpacing
            verticalAlignment: Text.AlignVCenter

            opacity: collapsed && ! forceExpand ?
                     theme.sidePane.account.collapsedOpacity : 1
            Behavior on opacity { HNumberAnimation {} }

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        HUIButton {
            id: expandButton
            iconName: "expand"
            iconDimension: 16
            backgroundColor: "transparent"
            leftPadding: sidePane.currentSpacing
            rightPadding: leftPadding
            onClicked: accountDelegate.toggleCollapse()

            visible: opacity > 0
            opacity:
                accountDelegate.forceExpand ? 0 :
                collapsed ? theme.sidePane.account.collapsedOpacity + 0.2 :
                1
            Behavior on opacity { HNumberAnimation {} }

            iconTransform: Rotation {
                origin.x: expandButton.iconDimension / 2
                origin.y: expandButton.iconDimension / 2

                angle: collapsed ? 180 : 90
                Behavior on angle { HNumberAnimation {} }
            }

            Layout.fillHeight: true
        }
    }
}
