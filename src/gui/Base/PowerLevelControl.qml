// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12

AutoDirectionLayout {
    id: root

    property int defaultLevel: 0
    property int maximumLevel: 100

    readonly property alias changed: field.changed

    readonly property int uncappedLevel: parseInt(field.text || "0", 10)
    readonly property int level: Math.min(maximumLevel, uncappedLevel)
    readonly property alias fieldFocused: field.activeFocus

    readonly property bool fieldOverMaximum:
        parseInt(field.text || "0", 10) > maximumLevel

    signal accepted()

    function reset() { field.reset() }


    rowSpacing: theme.spacing

    HSpacer {}

    HTextField {
        id: field

        radius: 0
        horizontalAlignment: Qt.AlignHCenter
        validator: IntValidator { top: root.maximumLevel }
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        maximumLength: root.level < 0 ? 16 : 3
        defaultText: String(root.defaultLevel)
        error: root.fieldOverMaximum

        onAccepted: root.accepted()
        onActiveFocusChanged:
            if (! activeFocus && fieldOverMaximum) text = root.maximumLevel

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
            toolTip.text: qsTr("Limited")
            checked: root.uncappedLevel < 50
            uncheckable: false
            onClicked: field.text = 0
        }

        HButton {
            height: parent.height
            icon.name: "user-power-50"
            toolTip.text: qsTr("Moderator")
            checked: root.uncappedLevel >= 50 && root.uncappedLevel < 100
            uncheckable: false
            onClicked: field.text = 50
        }

        HButton {
            height: parent.height
            icon.name: "user-power-100"
            toolTip.text: qsTr("Admin")
            checked: root.uncappedLevel >= 100
            uncheckable: false
            onClicked: field.text = 100
        }
    }

    HSpacer {}
}
