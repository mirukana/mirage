// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

BoxPopup {
    summary.text:
        isLast ?
        qsTr("Remove your last message?") :

        eventSenderAndIds.length > 1 ?
        qsTr("Remove %1 messages?").arg(eventSenderAndIds.length) :

        qsTr("Remove this message?")

    details.color: theme.colors.warningText
    details.text:
        onlyOwnMessageWarning ?
        qsTr("Only your messages can be removed") :
        ""

    okText: qsTr("Remove")
    box.focusButton: "ok"

    onOk: {
        const idsForSender = {}  // {senderId: [eventId, ...]}

        for (const [senderId, eventId] of eventSenderAndIds) {
            if (! idsForSender[senderId])
                idsForSender[senderId] = []

            idsForSender[senderId].push(eventId)
        }

        print( JSON.stringify( idsForSender, null, 4))

        for (const [senderId, eventIds] of Object.entries(idsForSender))
            py.callClientCoro(
                mainUI.accountIds.includes(senderId) ? senderId : preferUserId,
                "room_mass_redact",
                [roomId, reasonField.field.text, ...eventIds]
            )
    }


    property string preferUserId: ""
    property string roomId: ""

    property var eventSenderAndIds: []  // [[senderId, eventId], ...]
    property bool onlyOwnMessageWarning: false
    property bool isLast: false


    HLabeledTextField {
        id: reasonField
        label.text: qsTr("Optional reason:")
        Layout.fillWidth: true
    }
}
