// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

TextField {
    id: field
    text: defaultText
    opacity: enabled ? 1 : theme.disabledElementsOpacity
    selectByMouse: true
    leftPadding: theme.spacing
    rightPadding: leftPadding
    topPadding: theme.spacing / 1.5
    bottomPadding: topPadding

    font.family: theme.fontFamily.sans
    font.pixelSize: theme.fontSize.normal
    font.pointSize: -1

    placeholderTextColor: theme.controls.textField.placeholderText
    color: activeFocus ?
           theme.controls.textField.focusedText :
           theme.controls.textField.text

    background: Rectangle {
        id: textFieldBackground
        radius: theme.radius
        color: field.activeFocus ? focusedBackgroundColor : backgroundColor

        border.width: bordered ? theme.controls.textField.borderWidth : 0
        border.color: borderColor

        HRectangleBottomBorder {
            id: bottomBorder
            borderHeight: theme.controls.textField.borderWidth
            color: error ? errorBorder : focusedBorderColor

            transform: Scale {
                origin.x: bottomBorder.width / 2
                origin.y: bottomBorder.height / 2
                xScale: field.activeFocus ? 1 : 0

                Behavior on xScale { HNumberAnimation {} }
            }

            Behavior on color { HColorAnimation {} }
        }
    }

    // Set it only on component creation to avoid binding loops
    Component.onCompleted: if (! text) {
        text           = window.getState(this, "text", "")
        cursorPosition = text.length
    }

    onTextChanged: window.saveState(this)

    onActiveFocusChanged:
        text = activeFocus || changed ? text : Qt.binding(() => defaultText)

    Keys.onPressed: if (
        event.modifiers & Qt.AltModifier ||
        event.modifiers & Qt.MetaModifier
    ) event.accepted = true  // XXX Still needed?


    property string saveName: ""
    property var saveId: "ALL"
    property var saveProperties: ["text"]

    property bool error: false

    property alias radius: textFieldBackground.radius
    property bool bordered: true

    property color backgroundColor: theme.controls.textField.background
    property color borderColor: theme.controls.textField.border
    property color errorBorder: theme.controls.textField.errorBorder

    property color focusedBackgroundColor:
        theme.controls.textField.focusedBackground
    property color focusedBorderColor: theme.controls.textField.focusedBorder

    property var disabledText: null
    property string defaultText: ""
    readonly property bool changed: text !== defaultText


    function reset() { clear(); text = Qt.binding(() => defaultText)}


    Binding on color {
        value: "transparent"
        when: disabledText !== null && ! field.enabled
    }

    Binding on placeholderTextColor {
        value: "transparent"
        when: disabledText !== null && ! field.enabled
    }

    Binding on implicitHeight {
        value: disabledTextLabel.implicitHeight
        when: disabledText !== null && ! field.enabled
    }


    Behavior on opacity { HNumberAnimation {} }
    Behavior on color { HColorAnimation {} }
    Behavior on placeholderTextColor { HColorAnimation {} }

    HLabel {
        id: disabledTextLabel
        anchors.fill: parent
        visible: opacity > 0
        opacity: disabledText !== null && parent.enabled ? 0 : 1
        text: disabledText || ""

        leftPadding: parent.leftPadding
        rightPadding: parent.rightPadding
        topPadding: parent.topPadding
        bottomPadding: parent.bottomPadding

        wrapMode:
            parent.wrapMode === TextField.Wrap ? Text.Wrap :
            parent.wrapMode === TextField.WordWrap ? Text.WordWrap :
            parent.wrapMode === TextField.WrapAnywhere ? Text.WrapAnywhere :
            Text.NoWrap

        font.family: parent.font.family
        font.pixelSize: parent.font.pixelSize

        Behavior on opacity { HNumberAnimation {} }
    }
}
