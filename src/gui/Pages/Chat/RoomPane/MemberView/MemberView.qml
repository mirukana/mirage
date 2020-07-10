// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../.."
import "../../../../Base"

HColumnLayout {
    readonly property alias keybindFocusItem: filterField
    readonly property var modelSyncId:
        [chat.userId, chat.roomId, "filtered_members"]

    HStackView {
        id: stackView

        background: Rectangle {
            color: theme.chat.roomPane.listView.background
        }

        initialItem: HListView {
            id: memberList
            clip: true

            model: ModelStore.get(modelSyncId)

            delegate: MemberDelegate {
                id: member
                width: memberList.width

                onLeftClicked: stackView.push(
                    "MemberProfile.qml",
                    {
                        userId: chat.userId,
                        roomId: chat.roomId,
                        member: model,
                        stackView: stackView,
                    },
                )
            }

            Keys.onEnterPressed: Keys.onReturnPressed(event)
            Keys.onReturnPressed: {
                currentItem.leftClicked()
                currentItem.clicked()
            }

            Keys.onMenuPressed:
                if (currentItem) currentItem.doRightClick(false)
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    Rectangle {
        color: theme.chat.roomPane.bottomBar.background

        Layout.fillWidth: true
        Layout.minimumHeight: theme.baseElementsHeight
        Layout.maximumHeight: Layout.minimumHeight

        HRowLayout {
            anchors.fill: parent

            HTextField {
                id: filterField
                saveName: "memberFilterField"
                saveId: chat.roomId

                backgroundColor:
                    theme.chat.roomPane.bottomBar.filterMembers.background
                bordered: false
                opacity: width >= 16 * theme.uiScale ? 1 : 0

                Layout.fillWidth: true
                Layout.fillHeight: true

                // FIXME: fails to display sometimes for some reason if
                // declared normally
                Component.onCompleted: placeholderText = qsTr("Filter members")

                onTextChanged: {
                    stackView.pop(stackView.initialItem)
                    py.callCoro("set_substring_filter", [modelSyncId, text])
                }

                onActiveFocusChanged: {
                    if (
                        activeFocus &&
                        stackView.depth === 1 &&
                        stackView.currentItem.currentIndex === -1
                    ) {
                        stackView.currentItem.currentIndex = 0
                    } else if (
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
                    if (window.settings.clearMemberFilterOnEscape) text = ""
                }

                Behavior on opacity { HNumberAnimation {} }
            }

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

                onClicked: utils.makePopup(
                    "Popups/InviteToRoomPopup.qml",
                    {
                        userId: chat.userId,
                        roomId: chat.roomId,
                        roomName: chat.roomInfo.display_name,
                        invitingAllowed:
                            Qt.binding(() => inviteButton.enabled),
                    },
                )

                Layout.fillHeight: true

                HShortcut {
                    sequences: window.settings.keys.inviteToRoom
                    onActivated:
                        if (inviteButton.enabled) inviteButton.clicked()
                }
            }
        }
    }
}
