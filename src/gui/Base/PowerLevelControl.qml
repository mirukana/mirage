// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12

AutoDirectionLayout {
    id: control

    property int defaultLevel: 0

    readonly property alias changed: field.changed
    readonly property int level: Math.min(100, parseInt(field.text || "0", 10))

    function reset() { field.reset() }


    rowSpacing: theme.spacing

    HSpacer {}

    HTextField {
        id: field

        radius: 0
        horizontalAlignment: Qt.AlignHCenter
        validator: IntValidator { top: 100 }
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        maximumLength: control.level < 0 ? 16 : 3
        defaultText: String(control.defaultLevel)

        onActiveFocusChanged:
            if (! activeFocus && parseInt(text || "0", 10) > 100)
                text = 100

        Layout.minimumWidth:
            mainUI.fontMetrics.boundingRect("-999").width +
            leftPadding +
            rightPadding

        Layout.alignment: Qt.AlignCenter
    }

    Row {
        Layout.preferredHeight: field.height
        Layout.alignment: Qt.AlignCenter

        HButton {
            height: parent.height
            icon.name: "user-power-default"
            toolTip.text: qsTr("Default")
            checked: control.level >= 0 && control.level < 50
            uncheckable: false
            onClicked: field.text = 0
        }

        HButton {
            height: parent.height
            icon.name: "user-power-50"
            toolTip.text: qsTr("Moderator")
            checked: control.level >= 50 && control.level < 100
            uncheckable: false
            onClicked: field.text = 50
        }

        HButton {
            height: parent.height
            icon.name: "user-power-100"
            toolTip.text: qsTr("Admin")
            checked: control.level >= 100
            uncheckable: false
            onClicked: field.text = 100
        }
    }

    HSpacer {}
}
