// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

TextArea {
    id: textArea


    property string saveName: ""
    property var saveId: "ALL"
    property var saveProperties: ["text"]

    property bool error: false
    property alias radius: textAreaBackground.radius
    property bool bordered: true

    property var focusItemOnTab: null
    property var disabledText: null
    property var defaultText: null  // XXX test me
    readonly property bool changed: text !== (defaultText || "")

    property alias backgroundColor: textAreaBackground.color
    property color borderColor: theme.controls.textArea.border
    property color errorBorder: theme.controls.textArea.errorBorder
    property color focusedBorderColor: theme.controls.textArea.focusedBorder

    property string previousDefaultText: ""  // private


    function reset() { clear(); text = Qt.binding(() => defaultText || "") }
    function insertAtCursor(text) { insert(cursorPosition, text) }


    text: defaultText || ""
    opacity: enabled ? 1 : theme.disabledElementsOpacity
    selectByMouse: true
    leftPadding: theme.spacing
    rightPadding: leftPadding
    topPadding: theme.spacing / 1.5
    bottomPadding: topPadding
    readOnly: ! visible

    wrapMode: TextEdit.Wrap
    font.family: theme.fontFamily.sans
    font.pixelSize: theme.fontSize.normal
    font.pointSize: -1

    placeholderTextColor: theme.controls.textArea.placeholderText
    color: theme.controls.textArea.text

    background: Rectangle {
        id: textAreaBackground
        radius: theme.radius
        color: theme.controls.textArea.background

        border.width: bordered ? theme.controls.textArea.borderWidth : 0
        border.color: borderColor

        HBottomFocusLine {
            show: textArea.activeFocus
            borderHeight: theme.controls.textArea.borderWidth
            color: error ? errorBorder : focusedBorderColor
        }
    }

    Component.onCompleted: {
        // Break binding
        previousDefaultText = previousDefaultText

        // Set it only on component creation to avoid binding loops
        if (! text) {
            text           = window.getState(this, "text", "")
            cursorPosition = text.length
        }
    }

    onTextChanged: window.saveState(this)

    onActiveFocusChanged:
        if (defaultText !== null) text = text  // Break binding

    onDefaultTextChanged: if (defaultText !== null) {
        if (text === previousDefaultText)
            text = Qt.binding(() => defaultText)

        previousDefaultText = defaultText
    }

    // Prevent alt/super+any key from typing text
    Keys.onPressed: if (
        event.modifiers & Qt.AltModifier ||
        event.modifiers & Qt.MetaModifier
    ) event.accepted = true

    // Prevent leaking arrow presses to parent elements when the carret is at
    // the beginning or end of the text
    Keys.onLeftPressed: event.accepted = cursorPosition === 0 && ! selectedText
    Keys.onRightPressed:
        event.accepted = cursorPosition === length && ! selectedText

    KeyNavigation.priority: KeyNavigation.BeforeItem
    KeyNavigation.tab: focusItemOnTab


    Binding on color {
        value: "transparent"
        when: disabledText !== null && ! textArea.enabled
    }

    Binding on placeholderTextColor {
        value: "transparent"
        when: disabledText !== null && ! textArea.enabled
    }

    Binding on implicitHeight {
        value: disabledTextLabel.implicitHeight
        when: disabledText !== null && ! textArea.enabled
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
            parent.wrapMode === TextEdit.Wrap ? Text.Wrap :
            parent.wrapMode === TextEdit.WordWrap ? Text.WordWrap :
            parent.wrapMode === TextEdit.WrapAnywhere ? Text.WrapAnywhere :
            Text.NoWrap

        font.family: parent.font.family
        font.pixelSize: parent.font.pixelSize

        Behavior on opacity { HNumberAnimation {} }
    }
}
