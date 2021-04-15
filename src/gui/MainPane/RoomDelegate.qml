// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import ".."
import "../Base"
import "../Base/HTile"

HTile {
    id: room

    property string fetchProfilesFutureId: ""
    property string loadEventsFutureId: ""
    property bool moreToLoad: true

    readonly property bool joined: ! invited && ! parted
    readonly property bool invited: model.inviter_id && ! parted
    readonly property bool parted: model.left

    readonly property ListModel eventModel:
        ModelStore.get(model.for_account, model.id, "events")

    // FIXME: binding loop
    readonly property QtObject accountModel:
        ModelStore.get("accounts").find(model.for_account)

    readonly property QtObject lastEvent:
        eventModel.count > 0 ? eventModel.get(0) : null

    backgroundColor: theme.mainPane.listView.room.background
    leftPadding: theme.spacing * 2
    rightPadding: theme.spacing

    contentItem: ContentRow {
        tile: room
        opacity:
            accountModel.presence === "offline" ?
            theme.mainPane.listView.offlineOpacity :

            model.left ?
            theme.mainPane.listView.room.leftRoomOpacity :
            1

        Behavior on opacity { HNumberAnimation {} }

        HRoomAvatar {
            id: avatar
            clientUserId: model.for_account
            roomId: model.id
            displayName: model.display_name
            mxc: model.avatar_url
            compact: room.compact
            radius: theme.mainPane.listView.room.avatarRadius

            Behavior on radius { HNumberAnimation {} }
        }

        HColumnLayout {
            HRowLayout {
                spacing: room.spacing

                TitleLabel {
                    text:
                        // U+1f4cc pushpin + force black-and-white variant
                        (model.pinned ? "📌\ufe0e " : "") +
                        (model.display_name || qsTr("Empty room"))
                    color:
                        model.unreads || model.local_unreads ?
                        theme.mainPane.listView.room.unreadName :
                        theme.mainPane.listView.room.name
                }

                MessageIndicator {
                    indicatorTheme:
                        theme.mainPane.listView.room.unreadIndicator
                    unreads: model.unreads
                    highlights: model.highlights
                    localUnreads: model.local_unreads
                }

                HIcon {
                    svgName: "invite-received"
                    colorize: theme.colors.alertBackground
                    small: room.compact
                    visible: invited

                    Layout.maximumWidth: invited ? implicitWidth : 0

                    Behavior on Layout.maximumWidth { HNumberAnimation {} }
                }

                TitleRightInfoLabel {
                    tile: room
                    color: theme.mainPane.listView.room.lastEventDate
                    text: utils.smartFormatDate(model.last_event_date)
                }
            }

            SubtitleLabel {
                tile: room
                color: theme.mainPane.listView.room.subtitle
                textFormat: Text.StyledText
                font.italic:
                    lastEvent && lastEvent.event_type === "RoomMessageEmote"

                text: {
                    if (! lastEvent) return ""

                    const ev_type      = lastEvent.event_type
                    const isEmote      = ev_type === "RoomMessageEmote"
                    const isMsg        = ev_type.startsWith("RoomMessage")
                    const isUnknownMsg = ev_type === "RoomMessageUnknown"
                    const isCryptMedia = ev_type.startsWith("RoomEncrypted")

                    // If it's a general event
                    if (isEmote || isUnknownMsg || (! isMsg && ! isCryptMedia))
                        return utils.processedEventText(lastEvent)

                    const text = utils.coloredNameHtml(
                        lastEvent.sender_name, lastEvent.sender_id
                    ) + ": " + lastEvent.inline_content

                    const subColor =
                        theme.mainPane.listView.room.subtitleQuote

                    return text.replace(
                        /< *span +class=['"]?quote['"]? *>(.+?)<\/ *span *>/g,
                        `<font color="${subColor}">$1</font>`,
                    ).replace(
                        /< *mx-reply *>(.+?)<\/ *mx-reply *>/g,
                        `<font color="${theme.colors.accentText}">$1</font>`,
                    )
                }
            }
        }
    }

    contextMenu: HMenu {
        // This delegate is only used for nested menus
        delegate: HMenuItem { icon.name: "room-menu-notifications" }

        HMenuItem {
            icon.name: model.pinned ? "room-unpin": "room-pin"
            text: model.pinned ? qsTr("Unpin"): qsTr("Pin to top")
            onTriggered: py.callClientCoro(
                model.for_account, "toggle_room_pin", [model.id]
            )
        }

        HMenu {
            title: qsTr("Notifications")
            isSubMenu: true

            HMenuItem {
                text: qsTr("Use default account settings")
                checkable: true
                checked: model.notification_setting === "UseDefaultSettings"
                onTriggered: py.callClientCoro(
                    model.for_account, "room_pushrule_use_default", [model.id],
                )
            }

            HMenuItem {
                text: qsTr("All new messages")
                checkable: true
                checked: model.notification_setting === "AllEvents"
                onTriggered: py.callClientCoro(
                    model.for_account, "room_pushrule_all_events", [model.id],
                )
            }

            HMenuItem {
                text: qsTr("Highlights only (replies, keywords...)")
                checkable: true
                checked: model.notification_setting === "HighlightsOnly"
                onTriggered: py.callClientCoro(
                    model.for_account,
                    "room_pushrule_highlights_only",
                    [model.id],
                )
            }

            HMenuItem {
                text: qsTr("Ignore new messages")
                checkable: true
                checked: model.notification_setting === "IgnoreEvents"
                onTriggered: py.callClientCoro(
                    model.for_account, "room_pushrule_ignore_all", [model.id],
                )
            }
        }

        HMenuItemPopupSpawner {
            visible: joined
            enabled: model.can_invite && accountModel.presence !== "offline"
            icon.name: "room-send-invite"
            text: qsTr("Invite users")

            popup: "Popups/InviteToRoomPopup.qml"
            properties: ({
                userId: model.for_account,
                roomId: model.id,
                roomName: model.display_name,
                invitingAllowed: Qt.binding(() => model.can_invite)
            })
        }

        HMenuItem {
            icon.name: "copy-room-id"
            text: qsTr("Copy room ID")
            onTriggered: Clipboard.text = model.id
        }

        HMenuItem {
            visible: invited
            icon.name: "invite-accept"
            icon.color: theme.colors.positiveBackground
            text: qsTr("Accept %1's invite").arg(utils.coloredNameHtml(
                model.inviter_name, model.inviter_id
            ))
            label.textFormat: Text.StyledText
            enabled: accountModel.presence !== "offline"

            onTriggered: py.callClientCoro(
                model.for_account, "join", [model.id]
            )
        }

        HMenuItemPopupSpawner {
            enabled: accountModel.presence !== "offline"
            icon.color: theme.colors.negativeBackground
            icon.name:
                parted ? "room-forget" :
                invited ? "invite-decline" :
                "room-leave"

            text:
                parted ? qsTr("Forget history") :
                invited ? qsTr("Decline invite") :
                qsTr("Leave")

            popup: "Popups/LeaveRoomPopup.qml"
            properties: ({
                userId: model.for_account,
                roomId: model.id,
                roomName: model.display_name,
                inviterId: model.inviter_id,
                left: model.left,
            })
        }
    }

    Component.onDestruction: {
        if (fetchProfilesFutureId) py.cancelCoro(fetchProfilesFutureId)
        if (loadEventsFutureId) py.cancelCoro(loadEventsFutureId)
    }

    DelegateTransitionFixer {}

    Timer {
        interval: 1000
        triggeredOnStart: true
        running:
            ! accountModel.connecting &&
            accountModel.presence !== "offline" &&
            ! lastEvent &&
            moreToLoad

        onTriggered: if (! loadEventsFutureId) {
            loadEventsFutureId = py.callClientCoro(
                model.for_account,
                "load_past_events",
                [model.id],
                more => {
                    if (! room) return  // delegate was destroyed
                    loadEventsFutureId = ""
                    moreToLoad         = more
                }
            )
        }
    }

    Timer {
        // Ensure this event stays long enough for bothering to
        // fetch the profile to be worth it
        interval: 500
        running:
            ! accountModel.connecting &&
            accountModel.presence !== "offline" &&
            lastEvent &&
            lastEvent.fetch_profile

        onTriggered: {
            if (fetchProfilesFutureId) py.cancelCoro(fetchProfilesFutureId)

            fetchProfilesFutureId = py.callClientCoro(
                model.for_account,
                "get_event_profiles",
                [model.id, lastEvent.id],
                () => { if (room) fetchProfilesFutureId = "" },
            )
        }
    }
}
