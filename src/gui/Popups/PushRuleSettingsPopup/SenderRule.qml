// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

HColumnLayout {
    readonly property alias idField: idField

    HLabeledItem {
        label.text: qsTr("User ID:")
        Layout.fillWidth: true

        HTextField {
            id: idField
            width: parent.width
            defaultText: rule.kind === "sender" ? rule.rule_id : ""
            placeholderText: qsTr("@alice:example.org")
            maximumLength: 255
        }
    }
}
