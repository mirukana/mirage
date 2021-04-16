// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../.."
import "../../../Base"
import "../../../Base/Buttons"
import "../AutoCompletion"

Rectangle {
    id: root

    property UserAutoCompletion userCompletion
    property alias eventList: messageArea.eventList

    readonly property bool widthStarved: width < 384 * theme.uiScale
    readonly property bool parted: chat.roomInfo.left
    readonly property string inviterId: chat.roomInfo.inviter_id
    readonly property string inviterColoredName:
        utils.coloredNameHtml(chat.roomInfo.inviter_name, inviterId)

    readonly property bool hasFocus:
        messageArea.activeFocus ||
        joinButton.activeFocus ||
        exitButton.activeFocus

    readonly property alias messageArea: messageArea

    function takeFocus() {
        joinButton.visible ? joinButton.forceActiveFocus() :
        exitButton.visible ? exitButton.forceActiveFocus() :
        messageArea.forceActiveFocus()
    }

    implicitHeight: Math.max(theme.baseElementsHeight, row.implicitHeight)
    color: theme.chat.composer.background

    HRowLayout {
        id: row
        anchors.fill: parent

        HUserAvatar {
            id: avatar

            readonly property QtObject writerInfo:
                ModelStore.get("accounts").find(clientUserId)

            clientUserId: messageArea.writerId
            userId: clientUserId
            mxc: writerInfo ? writerInfo.avatar_url : ""
            displayName: writerInfo ? writerInfo.display_name : ""
            radius: 0
        }

        HScrollView {
            enabled: visible
            visible: ! root.inviterId && ! root.parted
            onVisibleChanged: if (root.hasFocus) root.takeFocus()

            Layout.fillHeight: true
            Layout.fillWidth: true

            MessageArea {
                id: messageArea
                autoCompletionOpen: userCompletion.open && userCompletion.count
                usersCompleted: userCompletion.usersCompleted

                onAutoCompletePrevious: userCompletion.previous()
                onAutoCompleteNext: userCompletion.next()
                onCancelAutoCompletion: userCompletion.cancel()
                onAcceptAutoCompletion:
                    ! userCompletion.autoOpen ||
                    userCompletion.autoOpenCompleted ?
                    userCompletion.accept() :
                    null
            }
        }

        UploadButton {
            visible: ! root.inviterId && ! root.parted
            onVisibleChanged: if (root.hasFocus) root.takeFocus()

            Layout.fillHeight: true
        }

        HLabel {
            textFormat: Text.StyledText
            wrapMode: HLabel.Wrap
            visible: root.inviterId || root.parted
            verticalAlignment: HLabel.AlignVCenter
            text:
                root.parted && root.inviterId ?
                qsTr("Declined %1's invite").arg(root.inviterColoredName) :

                root.parted ?
                qsTr("No longer part of this room") :

                qsTr("Invited by %1").arg(root.inviterColoredName)

            leftPadding: theme.spacing
            rightPadding: leftPadding
            topPadding: theme.spacing / 2
            bottomPadding: topPadding


            onVisibleChanged: if (root.hasFocus) root.takeFocus()

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        ApplyButton {
            id: joinButton
            icon.name: "invite-accept"
            text: widthStarved ? "" : qsTr("Join")
            visible: root.inviterId && ! root.parted
            onVisibleChanged: if (root.hasFocus) root.takeFocus()

            onClicked: {
                loading = true
                function callback() { joinButton.loading = false }
                py.callClientCoro(chat.userId, "join", [chat.roomId], callback)
            }

            Layout.fillWidth: false
            Layout.fillHeight: true

            Behavior on implicitWidth { HNumberAnimation {} }
        }

        CancelButton {
            id: exitButton
            icon.name: root.parted ? "room-forget" : "invite-decline"
            visible: root.inviterId || root.parted
            text:
                widthStarved ? "" :
                root.parted ? qsTr("Forget") :
                qsTr("Decline")

            onVisibleChanged: if (root.hasFocus) root.takeFocus()

            onClicked: {
                loading = true

                window.makePopup("Popups/LeaveRoomPopup.qml", {
                    userId: chat.userId,
                    roomId: chat.roomId,
                    roomName: chat.roomInfo.display_name,
                    inviterId: root.inviterId,
                    left: root.parted,
                    doneCallback: () => { exitButton.loading = false },
                })
            }

            Layout.fillWidth: false
            Layout.fillHeight: true

            Behavior on implicitWidth { HNumberAnimation {} }
        }
    }
}
