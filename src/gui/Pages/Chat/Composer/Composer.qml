// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../Base"

Rectangle {
    property alias eventList: messageArea.eventList
    readonly property bool hasFocus: messageArea.activeFocus

    function takeFocus() { messageArea.forceActiveFocus() }


    implicitHeight:
        Math.max(theme.baseElementsHeight, messageArea.implicitHeight)

    color: theme.chat.composer.background

    HRowLayout {
        anchors.fill: parent

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

            MessageArea { id: messageArea }
        }

        UploadButton {
            Layout.fillHeight: true
        }
    }
}
