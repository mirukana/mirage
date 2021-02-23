// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."
import "../../../Base"

CustomFlow {
    readonly property var matrixObject: ({
        kind: model.kind,
        is: operatorCombo.operators[operatorCombo.currentIndex]
                .replace("==", "") + countSpin.value,
    })

    CustomLabel {
        text: qsTr("Room has")
        verticalAlignment: CustomLabel.AlignVCenter
        height: operatorCombo.height
    }

    HComboBox {
        readonly property var operators: ["==", ">=", "<=", ">", "<"]

        id: operatorCombo
        width: Math.min(implicitWidth, parent.width)
        currentIndex: operators.indexOf(/[=<>]+/.exec(condition.is + "==")[0])
        model: [
            qsTr("exactly"),
            qsTr("at least"),
            qsTr("at most"),
            qsTr("more than"),
            qsTr("less than"),
        ]
    }

    HSpinBox {
        id: countSpin
        width: Math.min(implicitWidth, parent.width)
        defaultValue: parseInt(condition.is.replace(/[=<>]/, ""), 10)
    }

    CustomLabel {
        text: qsTr("members")
        verticalAlignment: CustomLabel.AlignVCenter
        height: operatorCombo.height
    }
}
