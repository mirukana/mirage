// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

SpinBox {
    id: box

    property var defaultValue: null
    readonly property bool changed: value !== (defaultValue || 0)

    function reset() { value = Qt.binding(() => defaultValue || 0) }


    // XXX TODO: default binding break
    value: defaultValue || 0
    implicitHeight: theme.baseElementsHeight
    padding: 0
    editable: true

    background: null

    contentItem: HTextField {
        id: textField
        height: parent.height
        implicitWidth: 90 * theme.uiScale
        radius: 0
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        // FIXME
        text: box.textFromValue(box.value, box.locale)

        readOnly: ! box.editable
        validator: box.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly

        onTextChanged: if (text && text !== "-") box.value = text
    }

    down.indicator: HButton {
        x: box.mirrored ? parent.width - width : 0
        height: parent.height
        font.pixelSize: theme.fontSize.biggest
        text: qsTr("-")
        autoRepeat: true
        autoRepeatInterval: 50

        onPressed: box.decrease()
    }

    up.indicator: HButton {
        x: box.mirrored ? 0 : parent.width - width
        height: parent.height
        font.pixelSize: theme.fontSize.biggest
        text: qsTr("+")
        autoRepeat: true
        autoRepeatInterval: 50

        onPressed: box.increase()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: textField.hovered ? Qt.IBeamCursor : Qt.ArrowCursor
        onWheel: wheel => {
            wheel.angleDelta.y < 0 ? box.decrease() : box.increase()
            wheel.accepted()
        }
    }
}
