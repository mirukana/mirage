// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../Base"
import "../AutoCompletion"

Rectangle {
    property UserAutoCompletion userCompletion
    property alias eventList: messageArea.eventList

    readonly property bool hasFocus: messageArea.activeFocus
    readonly property alias messageArea: messageArea

    function takeFocus() { messageArea.forceActiveFocus() }


    implicitHeight: Math.max(theme.baseElementsHeight, row.implicitHeight)
    color: theme.chat.composer.background

    HRowLayout {
        id: row
        anchors.fill: parent

        HUserAvatar {
            id: avatar
            radius: 0
            clientUserId: messageArea.writingUserId
            userId: messageArea.writingUserId

            mxc:
                messageArea.writingUserInfo ?
                messageArea.writingUserInfo.avatar_url :
                ""

            displayName:
                messageArea.writingUserInfo ?
                messageArea.writingUserInfo.display_name :
                ""
        }

        HScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true

            MessageArea {
                id: messageArea
                autoCompletionOpen: userCompletion.open
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
            Layout.fillHeight: true
        }
    }
}
