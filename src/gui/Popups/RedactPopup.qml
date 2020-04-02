// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

BoxPopup {
    summary.text:
        isLast ?
        qsTr("Remove your last message?") :

        eventIds.length > 1 ?
        qsTr("Remove %1 messages?").arg(eventIds.length) :

        qsTr("Remove this message?")

    details.color: theme.colors.warningText
    details.text:
        onlyOwnMessageWarning ?
        qsTr("Only your messages can be removed") :
        ""

    okText: qsTr("Remove")
    box.focusButton: "ok"

    onOk: py.callClientCoro(
        userId,
        "room_mass_redact",
        [roomId, reasonField.field.text, ...eventIds]
    )


    property string roomId: ""
    property string userId: ""

    property var eventIds: []
    property bool onlyOwnMessageWarning: false
    property bool isLast: false


    HLabeledTextField {
        id: reasonField
        label.text: qsTr("Optional reason:")
        Layout.fillWidth: true
    }
}
