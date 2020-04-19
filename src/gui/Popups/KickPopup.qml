// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

BoxPopup {
    summary.textFormat: Text.StyledText
    summary.text:
        targetIsInvited ?
        qsTr("Withdraw %1's invitation?").arg(coloredTarget) :
        qsTr("Kick %1 out of the room?").arg(coloredTarget)

    okText: qsTr("Kick")

    onOpened: reasonField.field.forceActiveFocus()
    onOk: py.callClientCoro(
        userId,
        "room_kick",
        [roomId, targetUserId, reasonField.field.text || null],
    )


    property string userId
    property string roomId
    property string targetUserId
    property string targetDisplayName
    property bool targetIsInvited: false

    readonly property string coloredTarget:
        utils.coloredNameHtml(targetDisplayName, targetUserId)


    HLabeledTextField {
        id: reasonField
        label.text: qsTr("Optional reason:")

        Layout.fillWidth: true
    }
}
