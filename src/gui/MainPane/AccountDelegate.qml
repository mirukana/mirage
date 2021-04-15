// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/HTile"

HTile {
    id: account

    property bool enableKeybinds: false
    property bool filterActive: false

    readonly property bool collapsed:
        (window.uiState.collapseAccounts[model.id] || false) &&
        ! filterActive

    readonly property alias avatar: title
    readonly property alias totalMessageIndicator: totalMessageIndicator
    readonly property alias title: title
    readonly property alias addChat: addChat
    readonly property alias expand: expand

    signal wentToAccountPage()

    function setCollapse(collapse) {
        window.uiState.collapseAccounts[model.id] = collapse
        window.saveUIState()

        py.callCoro("set_account_collapse", [model.id, collapse])
    }

    function toggleCollapse() {
        setCollapse(! collapsed)
    }

    function togglePresence(presence) {
        if (model.presence === presence) presence = "online"
        py.callClientCoro(model.id, "set_presence", [presence])
    }

    backgroundColor: theme.mainPane.listView.account.background

    contentItem: ContentRow {
        tile: account
        spacing: 0
        opacity:
            collapsed ?
            theme.mainPane.listView.account.collapsedOpacity :

            model.presence == "offline" ?
            theme.mainPane.listView.offlineOpacity :
            1

        Behavior on opacity { HNumberAnimation {} }

        HUserAvatar {
            id: avatar
            clientUserId: model.id
            userId: model.id
            displayName: model.display_name
            mxc: model.avatar_url
            radius: theme.mainPane.listView.account.avatarRadius
            compact: account.compact
            presence: model.presence

            Layout.alignment: Qt.AlignCenter

            HLoader {
                anchors.fill: parent
                z: 100
                opacity: model.connecting ? 1 : 0
                active: opacity > 0

                sourceComponent: Rectangle {
                    radius: avatar.radius
                    color: utils.hsluv(0, 0, 0, 0.6)

                    HBusyIndicator {
                        anchors.centerIn: parent
                        width: parent.width / 2
                        height: width
                    }
                }

                Behavior on opacity { HNumberAnimation {} }
            }

            MessageIndicator {
                id: totalMessageIndicator
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                z: 200

                indicatorTheme:
                    theme.mainPane.accountBar.account.unreadIndicator
                unreads: model.total_unread
                highlights: model.total_highlights
                localUnreads: model.local_unreads
            }

        }

        HColumnLayout {
            id: title

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

            SubtitleLabel {
                id: statusMsg
                tile: account
                text: utils.escapeHtml(model.status_msg.trim())
                visible: model.status_msg.trim()
                font.strikeout:
                    ! model.presence_support ||
                    model.presence.includes("offline") ||
                    model.presence.includes("invisible")

                Layout.leftMargin: theme.spacing
            }

            HoverHandler { id: nameHover }

            HToolTip {
                visible: nameHover.hovered
                text:
                    model.id +
                    (statusMsg.text ? " - " + model.status_msg.trim() : "")
            }
        }

        HButton {
            id: addChat
            iconItem.small: true
            icon.name: "add-chat"
            backgroundColor: "transparent"
            toolTip.text: qsTr("Add new chat")
            onClicked: {
                pageLoader.show(
                    "Pages/AddChat/AddChat.qml", {userId: model.id},
                )
                account.wentToAccountPage()
            }

            leftPadding: theme.spacing
            rightPadding: theme.spacing / 1.75

            Layout.fillHeight: true
            Layout.maximumWidth:
                account.width >= 100 * theme.uiScale ?  implicitWidth : 0

            HShortcut {
                enabled: enableKeybinds
                sequences: window.settings.Keys.Rooms.add
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

    contextMenu: AccountContextMenu {
        userId: model.id
        statusMsg: model.status_msg
        presence:
            model.presence_support || model.presence === "offline" ?
            model.presence :
            null
        onWentToAccountPage: account.wentToAccountPage()
    }

    HShortcut {
        enabled: enableKeybinds
        sequences: window.settings.Keys.Accounts.settings
        onActivated: leftClicked()
    }

    HShortcut {
        enabled: enableKeybinds
        sequences: window.settings.Keys.Accounts.collapse
        onActivated: toggleCollapse()
    }

    HShortcut {
        enabled: enableKeybinds
        sequences: window.settings.Keys.Accounts.menu
        onActivated: account.doRightClick(false)
    }

    HShortcut {
        enabled: enableKeybinds
        sequences: window.settings.Keys.Accounts.unavailable
        onActivated: account.togglePresence("unavailable")
    }

    HShortcut {
        enabled: enableKeybinds
        sequences: window.settings.Keys.Accounts.invisible
        onActivated: account.togglePresence("invisible")
    }

    HShortcut {
        enabled: enableKeybinds
        sequences: window.settings.Keys.Accounts.offline
        onActivated: account.togglePresence("offline")
    }

    DelegateTransitionFixer {}
}
