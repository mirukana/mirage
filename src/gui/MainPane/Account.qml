// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/HTile"

HTileDelegate {
    id: account
    backgroundColor: theme.mainPane.listView.account.background
    leftPadding: theme.spacing
    rightPadding: 0  // the right buttons have padding

    contentItem: ContentRow {
        tile: account
        spacing: 0
        opacity: collapsed ? theme.mainPane.listView.account.collapsedOpacity : 1

        Behavior on opacity { HNumberAnimation {} }

        HUserAvatar {
            id: avatar
            userId: model.id
            displayName: model.display_name
            mxc: model.avatar_url
            radius: theme.mainPane.listView.account.avatarRadius
            compact: account.compact
        }

        TitleLabel {
            text: model.display_name || model.id
            color:
                hovered ?
                utils.nameColor(
                    model.display_name || model.id.substring(1),
                ) :
                theme.mainPane.listView.account.name

            Behavior on color { HColorAnimation {} }

            Layout.leftMargin: theme.spacing
        }

        HButton {
            id: addChat
            iconItem.small: true
            icon.name: "add-chat"
            backgroundColor: "transparent"
            toolTip.text: qsTr("Add new chat")
            onClicked: pageLoader.showPage(
                "AddChat/AddChat", {userId: model.id},
            )

            leftPadding: theme.spacing
            rightPadding: theme.spacing / 1.75

            Layout.fillHeight: true
            Layout.maximumWidth:
                account.width >= 100 * theme.uiScale ?  implicitWidth : 0

            HShortcut {
                enabled: isCurrent
                sequences: window.settings.keys.addNewChat
                onActivated: addChat.clicked()
            }
        }

        HButton {
            id: expand
            iconItem.small: true
            icon.name: "expand"
            backgroundColor: "transparent"
            toolTip.text: collapsed ? qsTr("Expand") : qsTr("Collapse")
            onClicked: account.toggleCollapse()

            leftPadding: theme.spacing / 1.75
            rightPadding: theme.spacing

            visible: Layout.maximumWidth > 0

            Layout.fillHeight: true
            Layout.maximumWidth:
                ! filterActive && account.width >= 120 * theme.uiScale ?
                implicitWidth :
                0

            iconItem.transform: Rotation {
                origin.x: expand.iconItem.width / 2
                origin.y: expand.iconItem.height / 2
                angle: expand.loading ? 0 : collapsed ? 180 : 90

                Behavior on angle { HNumberAnimation {} }
            }

            Behavior on Layout.maximumWidth { HNumberAnimation {} }
        }
    }

    contextMenu: AccountContextMenu { userId: model.id }

    onLeftClicked: {
        pageLoader.showPage(
            "AccountSettings/AccountSettings", { "userId": model.id }
        )
    }


    property bool isCurrent: false
    property bool filterActive: false

    readonly property bool collapsed:
        (window.uiState.collapseAccounts[model.id] || false) &&
        ! filterActive


    function setCollapse(collapse) {
        window.uiState.collapseAccounts[model.id] = collapse
        window.uiStateChanged()

        py.callCoro("set_account_collapse", [model.id, collapse])
    }

    function toggleCollapse() {
        setCollapse(! collapsed)
    }


    HShortcut {
        enabled: isCurrent
        sequences: window.settings.keys.accountSettings
        onActivated: leftClicked()
    }

    HShortcut {
        enabled: isCurrent
        sequences: window.settings.keys.toggleCollapseAccount
        onActivated: toggleCollapse()
    }
}
