// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/Buttons"

HFlickableColumnPopup {
    id: popup


    property string preferUserId: ""
    property string roomId: ""

    property var eventSenderAndIds: []  // [[senderId, event.id], ...]
    property bool onlyOwnMessageWarning: false
    property bool isLast: false


    function remove() {
        const idsForSender = {}  // {senderId: [event.id, ...]}

        for (const [senderId, eventClientId] of eventSenderAndIds) {
            if (! idsForSender[senderId])
                idsForSender[senderId] = []

            idsForSender[senderId].push(eventClientId)
        }

        for (const [senderId, eventClientIds] of Object.entries(idsForSender))
            py.callClientCoro(
                mainUI.accountIds.includes(senderId) ? senderId : preferUserId,
                "room_mass_redact",
                [roomId, reasonField.item.text, ...eventClientIds]
            )

        popup.close()
    }


    page.footer: AutoDirectionLayout {
        ApplyButton {
            text: qsTr("Remove")
            icon.name: "remove-message"
            onClicked: remove()
        }

        CancelButton {
            onClicked: popup.close()
        }
    }

    onOpened: reasonField.item.forceActiveFocus()
    onKeyboardAccept: popup.remove()


    SummaryLabel {
        text:
            isLast ?
            qsTr("Remove your last message?") :

            eventSenderAndIds.length > 1 ?
            qsTr("Remove %1 messages?").arg(eventSenderAndIds.length) :

            qsTr("Remove this message?")
    }

    DetailsLabel {
        color: theme.colors.warningText
        text:
            onlyOwnMessageWarning ?
            qsTr("Only your messages can be removed") :
            ""
    }

    HLabeledItem {
        id: reasonField
        label.text: qsTr("Optional reason:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
        }
    }
}
