// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

SpinBox {
    id: box

    property var defaultValue: null
    readonly property bool changed: value !== (defaultValue || 0)

    function reset() { value = Qt.binding(() => defaultValue || 0) }

    value: defaultValue || 0
    implicitHeight: theme.baseElementsHeight
    padding: 0
    editable: true
    to: 2147483647

    background: null

    contentItem: HRowLayout {
        HButton {
            text: qsTr("-")
            font.pixelSize: theme.fontSize.biggest
            autoRepeat: true
            autoRepeatInterval: 50
            // Don't set enabled to false or it glitches, use opacity instead
            opacity: box.value > box.from ? 1 : theme.disabledElementsOpacity
            onPressed: if (box.value > box.from) box.decrease()
            Layout.fillHeight: true

            Behavior on opacity { HNumberAnimation {} }
        }

        HTextField {
            id: textField
            height: parent.height
            implicitWidth: 90 * theme.uiScale
            radius: 0
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            text: box.value

            readOnly: ! box.editable
            validator: box.validator
            inputMethodHints: Qt.ImhFormattedNumbersOnly

            onTextEdited: {
                if (! text || text === "-") return
                const input = parseInt(text, 10)
                box.value   = Math.max(box.from, Math.min(box.to, input))
            }
        }

        HButton {
            text: qsTr("+")
            font.pixelSize: theme.fontSize.biggest
            autoRepeat: true
            autoRepeatInterval: 50
            opacity: box.value < box.to ? 1 : theme.disabledElementsOpacity
            onPressed: if (box.value < box.to) box.increase()
            Layout.fillHeight: true

            Behavior on opacity { HNumberAnimation {} }
        }
    }

    down.indicator: null
    up.indicator: null

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: textField.hovered ? Qt.IBeamCursor : Qt.ArrowCursor
        onWheel: wheel => {
            wheel.angleDelta.y < 0 ? box.decrease() : box.increase()
            wheel.accepted = true
        }
    }
}
