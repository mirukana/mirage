// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../.."
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

            readonly property QtObject writerInfo:
                ModelStore.get("accounts").find(clientUserId)

            clientUserId: messageArea.writerId
            userId: clientUserId
            mxc: writerInfo ? writerInfo.avatar_url : ""
            displayName: writerInfo ? writerInfo.display_name : ""
            radius: 0
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
