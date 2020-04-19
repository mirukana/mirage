// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

BoxPopup {
    summary.textFormat: Text.StyledText
    summary.text:
        operation === RemoveMemberPopup.Operation.Disinvite ?
        qsTr("Disinvite %1 from the room?").arg(coloredTarget) :

        operation === RemoveMemberPopup.Operation.Kick ?
        qsTr("Kick %1 out of the room?").arg(coloredTarget) :

        qsTr("Ban %1 from the room?").arg(coloredTarget)

    okText:
        operation === RemoveMemberPopup.Operation.Disinvite ?
        qsTr("Disinvite") :

        operation === RemoveMemberPopup.Operation.Kick ?
        qsTr("Kick") :

        qsTr("Ban")

    onOpened: reasonField.field.forceActiveFocus()
    onOk: py.callClientCoro(
        userId,
        operation === RemoveMemberPopup.Operation.Ban ?
        "room_ban" : "room_kick",
        [roomId, targetUserId, reasonField.field.text || null],
    )


    enum Operation { Disinvite, Kick, Ban }

    property string userId
    property string roomId
    property string targetUserId
    property string targetDisplayName
    property int operation

    readonly property string coloredTarget:
        utils.coloredNameHtml(targetDisplayName, targetUserId)


    HLabeledTextField {
        id: reasonField
        label.text: qsTr("Optional reason:")

        Layout.fillWidth: true
    }
}
