// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import "../Base"
import "../Base/HTile"

HTileDelegate {
    id: account
    rightPadding: 0
    backgroundColor: theme.mainPane.listView.account.background
    opacity: collapsed && ! mainPane.filter ?
             theme.mainPane.listView.account.collapsedOpacity : 1

    contentItem: ContentRow {
        tile: account
        spacing: 0

        HUserAvatar {
            id: avatar
            userId: model.id
            displayName: model.display_name
            mxc: model.avatar_url
            compact: account.compact

            radius:
                mainPane.small ?
                theme.mainPane.listView.account.collapsedAvatarRadius :
                theme.mainPane.listView.account.avatarRadius

            Behavior on radius { HNumberAnimation {} }
        }

        TitleLabel {
            text: model.display_name || model.id
            font.pixelSize: theme.fontSize.big
            color:
                hovered ?
                utils.nameColor(model.display_name || model.id.substring(1)) :
                theme.mainPane.listView.account.name

            Layout.leftMargin: theme.spacing
            Layout.rightMargin: theme.spacing

            Behavior on color { HColorAnimation {} }
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

            leftPadding: theme.spacing / 2
            rightPadding: leftPadding

            opacity: expand.loading ? 0 : 1
            visible: opacity > 0 && Layout.maximumWidth > 0

            Layout.fillHeight: true
            Layout.maximumWidth:
                account.width >= 100 * theme.uiScale ?  implicitWidth : 0

            Behavior on Layout.maximumWidth { HNumberAnimation {} }
            Behavior on opacity { HNumberAnimation {} }
        }

        HButton {
            id: expand
            loading:
                ! model.first_sync_done || model.profile_updated < new Date(1)
            iconItem.small: true
            icon.name: "expand"
            backgroundColor: "transparent"
            toolTip.text: collapsed ? qsTr("Expand") : qsTr("Collapse")
            onClicked: account.toggleCollapse()

            leftPadding: theme.spacing / 2
            rightPadding: theme.spacing

            opacity: ! loading && mainPane.filter ? 0 : 1
            visible: opacity > 0 && Layout.maximumWidth > 0

            Layout.fillHeight: true
            Layout.maximumWidth:
                account.width >= 120 * theme.uiScale ?  implicitWidth : 0


            iconItem.transform: Rotation {
                origin.x: expand.iconItem.width / 2
                origin.y: expand.iconItem.height / 2
                angle: expand.loading ? 0 : collapsed ? 180 : 90

                Behavior on angle { HNumberAnimation {} }
            }

            Behavior on Layout.maximumWidth { HNumberAnimation {} }
            Behavior on opacity { HNumberAnimation {} }
        }
    }

    contextMenu: HMenu {
        HMenuItem {
            icon.name: "copy-user-id"
            text: qsTr("Copy user ID")
            onTriggered: Clipboard.text = model.id
        }

        HMenuItemPopupSpawner {
            icon.name: "sign-out"
            icon.color: theme.colors.negativeBackground
            text: qsTr("Sign out")

            popup: "Popups/SignOutPopup.qml"
            properties: { "userId": model.id }
        }
    }

    onActivated: {
        pageLoader.showPage(
            "AccountSettings/AccountSettings", { "userId": model.id }
        )
        mainPaneList.detachedCurrentIndex = false
        mainPaneList.centerToHighlight    = false
    }


    readonly property alias addChat: addChat

    readonly property bool collapsed:
        (window.uiState.collapseAccounts[model.id] || false) &&
        ! mainPane.filter


    function setCollapse(collapse) {
        window.uiState.collapseAccounts[model.id] = collapse
        window.uiStateChanged()
    }

    function toggleCollapse() {
        setCollapse(! collapsed)
    }


    Behavior on opacity { HNumberAnimation {} }
    Behavior on leftPadding { HNumberAnimation {} }
    Behavior on topPadding { HNumberAnimation {} }

    Binding on leftPadding {
        value: (mainPane.minimumSize - avatar.width) / 2
        when: mainPane.small
    }

    Binding on topPadding {
        value: theme.spacing
        when: mainPane.small
    }

    Binding on bottomPadding {
        value: theme.spacing
        when: mainPane.small
    }
}
