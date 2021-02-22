// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."
import "../../../Base"

CustomFlow {
    readonly property var matrixObject: ({
        kind: "event_match",
        key: keyCombo.editText,
        pattern: patternField.text,
    })

    CustomLabel {
        text: qsTr("Message")
        verticalAlignment: CustomLabel.AlignVCenter
        height: keyCombo.height
    }

    HComboBox {
        id: keyCombo
        width: Math.min(implicitWidth, parent.width)
        editText: condition.key
        editable: true
        currentIndex: model.indexOf(condition.key)
        model: [...new Set([
            "content.body",
            "content.msgtype",
            "room_id",
            "sender",
            "state_key",
            "type",
            condition.key,
        ])].sort()
    }

    CustomLabel {
        text: keyCombo.editText === "content.body" ? qsTr("has") : qsTr("is")
        verticalAlignment: CustomLabel.AlignVCenter
        height: keyCombo.height
    }

    HTextField {
        id: patternField
        defaultText: condition.pattern
        width: Math.min(implicitWidth, parent.width)
        placeholderText: ({
            "content.body": qsTr("text..."),
            "content.msgtype": qsTr("e.g. m.image"),
            "room_id": qsTr("!room:example.org"),
            "sender": qsTr("@user:example.org"),
            "state_key": qsTr("@user:example.org"),
            "type": qsTr("e.g. m.room.message"),
        }[keyCombo.editText] || qsTr("value"))
    }
}
