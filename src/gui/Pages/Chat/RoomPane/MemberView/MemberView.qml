// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../.."
import "../../../../Base"

HColumnLayout {
    readonly property alias keybindFocusItem: filterField
    readonly property var modelSyncId:
        [chat.userRoomId[0], chat.userRoomId[1], "filtered_members"]

    readonly property alias viewDepth: stackView.depth
    readonly property alias filterField: filterField

    Connections {
        target: pageLoader
        onAboutToRecycle: {
            stackView.pop(stackView.initialItem)
            filterField.reset()
        }
    }

    HStackView {
        id: stackView

        background: Rectangle {
            color: theme.chat.roomPane.listView.background
        }

        initialItem: HListView {
            id: memberList
            clip: true

            delegate: MemberDelegate {
                id: member
                width: memberList.width
                colorName: hovered || memberList.currentIndex === model.index

                onLeftClicked: stackView.push(
                    "MemberProfile.qml",
                    {
                        userId: chat.userId,
                        roomId: chat.roomId,
                        ownPowerLevel:
                            Qt.binding(() => chat.roomInfo.own_power_level),
                        canSetPowerLevels: Qt.binding(() =>
                            chat.userInfo.presence !== "offline" &&
                            chat.roomInfo.can_set_power_levels
                        ),
                        member: model,
                        stackView: stackView,
                        focusOnExit: filterField,
                    },
                )
            }

            Keys.onTabPressed: memberList.incrementCurrentIndex()
            Keys.onBacktabPressed: memberList.decrementCurrentIndex()

            Keys.onEnterPressed: Keys.onReturnPressed(event)
            Keys.onReturnPressed: {
                currentItem.leftClicked()
                currentItem.clicked()
            }

            Keys.onMenuPressed:
                if (currentItem) currentItem.doRightClick(false)

            Timer {
                id: updateModelTimer
                interval: pageLoader.appearAnimation.duration
                running: true
                onTriggered: memberList.model = ModelStore.get(modelSyncId)
            }

            Connections {
                target: pageLoader
                onRecycled: {
                    memberList.model = null
                    updateModelTimer.restart()
                }
            }
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    Rectangle {
        color: theme.chat.roomPane.bottomBar.background

        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height

        HRowLayout {
            width: parent.width
            layoutDirection:
                expandButton.visible ? Qt.RightToLeft : Qt.LeftToRight

            HTextField {
                id: filterField

                backgroundColor:
                    theme.chat.roomPane.bottomBar.filterMembers.background
                bordered: false
                opacity: width >= 16 * theme.uiScale ? 1 : 0

                Layout.fillWidth: true

                // FIXME: fails to display sometimes for some reason if
                // declared normally
                Component.onCompleted: placeholderText = qsTr("Filter members")

                onTextChanged: {
                    stackView.pop(stackView.initialItem)
                    if (! stackView.currentItem.model) return
                    py.callCoro("set_string_filter", [modelSyncId, text])
                }

                onActiveFocusChanged: {
                    if (
                        ! activeFocus &&
                        stackView.depth === 1 &&
                        stackView.currentItem.currentIndex === 0
                    ) {
                        stackView.currentItem.currentIndex = -1
                    }
                }

                Keys.forwardTo: [stackView.currentItem]
                Keys.priority: Keys.AfterItem

                Keys.onEscapePressed: {
                    if (stackView.depth === 1)
                        stackView.currentItem.currentIndex = -1

                    roomPane.toggleFocus()

                    if (window.settings.RoomList.escape_clears_filter)
                        text = ""
                }

                Behavior on opacity { HNumberAnimation {} }
            }

            HColumnLayout {
                HButton {
                    id: inviteButton
                    icon.name: "room-send-invite"
                    backgroundColor:
                        theme.chat.roomPane.bottomBar.inviteButton.background
                    enabled:
                        chat.userInfo.presence !== "offline" &&
                        chat.roomInfo.can_invite

                    toolTip.text:
                        enabled ?
                        qsTr("Invite members to this room") :
                        qsTr("No permission to invite members to this room")

                    onClicked: window.makePopup(
                        "Popups/InviteToRoomPopup.qml",
                        {
                            userId: chat.userId,
                            roomId: chat.roomId,
                            roomName: chat.roomInfo.display_name,
                            invitingAllowed:
                                Qt.binding(() => inviteButton.enabled),
                        },
                    )

                    Layout.preferredHeight: filterField.implicitHeight

                    HShortcut {
                        sequences: window.settings.Keys.Chat.invite
                        onActivated:
                            if (inviteButton.enabled) inviteButton.clicked()
                    }
                }

                HButton {
                    id: expandButton
                    icon.name: "room-pane-expand-search"
                    backgroundColor: inviteButton.backgroundColor
                    toolTip.text: qsTr("Expand search")
                    visible: Layout.preferredHeight > 0

                    // Will trigger roomPane.requireDefaultSize
                    onClicked: filterField.forceActiveFocus()

                    Layout.preferredHeight:
                        filterField.width < 32 * theme.uiScale ?
                        filterField.implicitHeight :
                        0

                    Behavior on Layout.preferredHeight { HNumberAnimation {} }
                }
            }
        }
    }
}
