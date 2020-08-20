// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../Base"

Rectangle {
    property alias eventList: messageArea.eventList
    readonly property bool hasFocus: messageArea.activeFocus

    function takeFocus() { messageArea.forceActiveFocus() }


    implicitHeight: Math.max(theme.baseElementsHeight, column.implicitHeight)
    color: theme.chat.composer.background

    HColumnLayout {
        id: column
        anchors.fill: parent

        UserAutoCompletion {
            id: userCompletion
            textArea: messageArea

            Layout.fillWidth: true
            Layout.maximumHeight: chat.height / 3
        }

        HRowLayout {
            HUserAvatar {
                id: avatar
                radius: 0
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

                    onAutoCompletePrevious: userCompletion.previous()
                    onAutoCompleteNext: userCompletion.next()
                    onCancelAutoCompletion: userCompletion.cancel()
                    onExtraCharacterCloseAutoCompletion:
                        ! userCompletion.autoOpen ||
                        userCompletion.autoOpenCompleted ?
                        userCompletion.open = false :
                        null
                }
            }

            UploadButton {
                Layout.fillHeight: true
            }
        }
    }
}
