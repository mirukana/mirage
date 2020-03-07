// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import "../Base"

HTileDelegate {
    id: account
    spacing: 0
    topPadding: model.index > 0 ? theme.spacing / 2 : 0
    bottomPadding: topPadding

    backgroundColor: theme.mainPane.account.background
    opacity: collapsed && ! mainPane.filter ?
             theme.mainPane.account.collapsedOpacity : 1

    title.color: theme.mainPane.account.name
    title.text: model.display_name || model.id
    title.font.pixelSize: theme.fontSize.big
    title.leftPadding: theme.spacing

    image: HUserAvatar {
        userId: model.id
        displayName: model.display_name
        mxc: model.avatar_url
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

    onActivated: pageLoader.showPage(
        "AccountSettings/AccountSettings", { "userId": model.id }
    )


    readonly property alias addChat: addChat

    readonly property bool collapsed:
        window.uiState.collapseAccounts[model.id] || false

    readonly property bool shouldBeSelected:
        (
            window.uiState.page === "Pages/AddChat/AddChat.qml" ||
            window.uiState.page === "Pages/AccountSettings/AccountSettings.qml"
        ) &&
        window.uiState.pageProperties.userId === model.id


    function becomeSelected() {
        accountRooms.roomList.currentIndex = -1
        mainPaneList.currentIndex          = index
    }

    function toggleCollapse() {
        window.uiState.collapseAccounts[model.id] = ! collapsed
        window.uiStateChanged()
    }


    Behavior on opacity { HNumberAnimation {} }


    // Trying to set the current item to ourself usually won't work from the
    // first time, when this delegate is being initialized
    Timer {
        interval: 100
        repeat: true
        running: shouldBeSelected && mainPaneList.currentIndex === -1
        triggeredOnStart: true
        onTriggered: becomeSelected()
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
        rightPadding: leftPadding

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
