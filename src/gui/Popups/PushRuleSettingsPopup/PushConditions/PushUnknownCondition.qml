// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."
import "../../../Base"

AutoDirectionLayout {
    readonly property var matrixObject: {
        try {
            JSON.parse(jsonField.text)
        } catch (e) {
            // TODO
            return condition.condition
        }
    }

    rowSpacing: theme.spacing / 2
    columnSpacing: rowSpacing

    CustomLabel {
        text: qsTr("Custom JSON:")
        verticalAlignment: CustomLabel.AlignVCenter
        Layout.fillWidth: false
        Layout.fillHeight: true
    }

    HTextField {
        // TODO: validate the JSON
        id: jsonField
        font.family: theme.fontFamily.mono
        defaultText: JSON.stringify(condition.condition)
        Layout.fillWidth: true
    }
}
