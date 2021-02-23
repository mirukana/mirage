// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."
import "../../../Base"

CustomFlow {
    readonly property var matrixObject: ({
        kind: model.kind,
        key: keyCombo.editText,
    })

    CustomLabel {
        text: qsTr("Sender has permission to send")
        verticalAlignment: CustomLabel.AlignVCenter
        height: keyCombo.height
    }

    HComboBox {
        id: keyCombo
        width: Math.min(implicitWidth, parent.width)
        editable: true
        editText: condition.key
        currentIndex: model.indexOf(condition.key)
        model: [...new Set(["room", condition.key])].sort()
    }

    CustomLabel {
        text: qsTr("notifications")
        verticalAlignment: CustomLabel.AlignVCenter
        height: keyCombo.height
    }
}
