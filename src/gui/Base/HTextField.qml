// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

TextField {
    id: field

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
    property var defaultText: null
    readonly property bool changed: text !== (defaultText || "")

    property string previousDefaultText: ""  // private

    function reset() {
        clear()
        text = Qt.binding(() => defaultText || "")
    }

    function loadState() {
        if (! text) insertAtCursor(window.getState(this, "text", ""))
    }

    function insertAtCursor(text) {
        insert(cursorPosition, text)
    }


    text: defaultText || ""
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

        HBottomFocusLine {
            show: field.activeFocus
            borderHeight: theme.controls.textField.borderWidth
            color: error ? errorBorder : focusedBorderColor
        }
    }

    Component.onCompleted: {
        // Break binding
        previousDefaultText = previousDefaultText
        loadState()
    }

    onTextChanged: window.saveState(this)

    onActiveFocusChanged:
        if (defaultText !== null) text = text  // Break binding

    onDefaultTextChanged: if (defaultText !== null) {
        if (text === previousDefaultText)
            text = Qt.binding(() => defaultText)

        previousDefaultText = defaultText
    }

    onPressed: ev => { if (ev.button === Qt.RightButton) contextMenu.spawn() }
    onPressAndHold: ev => contextMenu.spawn()

    // Prevent alt/super+any key from typing text
    Keys.onPressed: if (
        event.modifiers & Qt.AltModifier ||
        event.modifiers & Qt.MetaModifier
    ) event.accepted = true

    Keys.onMenuPressed: contextMenu.spawn(false)

    // Prevent leaking arrow presses to parent elements when the carret is at
    // the beginning or end of the text
    Keys.onLeftPressed: event.accepted = cursorPosition === 0 && ! selectedText
    Keys.onRightPressed:
        event.accepted = cursorPosition === length && ! selectedText


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
            parent.wrapMode === TextField.Wrap ? HLabel.Wrap :
            parent.wrapMode === TextField.WordWrap ? HLabel.WordWrap :
            parent.wrapMode === TextField.WrapAnywhere ? HLabel.WrapAnywhere :
            Text.NoWrap

        font.family: parent.font.family
        font.pixelSize: parent.font.pixelSize

        Behavior on opacity { HNumberAnimation {} }
    }

    HTextContextMenu { id: contextMenu }
}
