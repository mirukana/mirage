// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

BoxPopup {
    summary.text:
        eventIds.length > 1 ?
        qsTr("Remove selected messages?") :
        qsTr("Remove selected message?")

    details.color: theme.colors.warningText
    details.text:
        onlyOwnMessageWarning ?
        qsTr("Only your messages will be removed") :
        ""

    HLabeledTextField {
        id: reasonField
        label.text: qsTr("Reason (optional):")
        Layout.fillWidth: true
    }

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
}
