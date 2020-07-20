// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import Clipboard 0.1

TextArea {
    id: textArea

    property string saveName: ""
    property var saveId: "ALL"
    property var saveProperties: ["text"]

    property bool error: false
    property alias radius: textAreaBackground.radius
    property bool bordered: true

    property var focusItemOnTab: null
    property bool menuKeySpawnsMenu: true
    property var disabledText: null
    property var defaultText: null  // XXX test me
    readonly property bool changed: text !== (defaultText || "")

    property alias backgroundColor: textAreaBackground.color
    property color borderColor: theme.controls.textArea.border
    property color errorBorder: theme.controls.textArea.errorBorder
    property color focusedBorderColor: theme.controls.textArea.focusedBorder

    property string previousDefaultText: ""  // private

    property bool enableCustomImagePaste: false

    signal customImagePaste()

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
        opacity: textArea.opacity

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

    Keys.onPressed: ev => {
        // Prevent alt/super+any key from typing text
        if (
            ev.modifiers & Qt.AltModifier ||
            ev.modifiers & Qt.MetaModifier
        ) ev.accepted = true

        if (
            ev.matches(StandardKey.Paste) &&
            textArea.enableCustomImagePaste &&
            Clipboard.hasImage
        ) {
            ev.accepted = true
            textArea.customImagePaste()
        }
    }

    Keys.onMenuPressed: if (menuKeySpawnsMenu) contextMenu.spawn(false)

    // Prevent leaking arrow presses to parent elements when the carret is at
    // the beginning or end of the text
    Keys.onLeftPressed:
        event.accepted = readOnly || (cursorPosition === 0 && ! selectedText)
    Keys.onRightPressed:
        event.accepted =
            readOnly || (cursorPosition === length && ! selectedText)

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
            parent.wrapMode === TextEdit.Wrap ? HLabel.Wrap :
            parent.wrapMode === TextEdit.WordWrap ? HLabel.WordWrap :
            parent.wrapMode === TextEdit.WrapAnywhere ? HLabel.WrapAnywhere :
            Text.NoWrap

        font.family: parent.font.family
        font.pixelSize: parent.font.pixelSize

        Behavior on opacity { HNumberAnimation {} }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Pen
        onTapped: contextMenu.spawn()
    }

    TapHandler {
        acceptedPointerTypes: PointerDevice.Finger | PointerDevice.Pen
        onLongPressed: contextMenu.spawn()
    }

    HTextContextMenu {
        id: contextMenu
        enableCustomImagePaste: textArea.enableCustomImagePaste
        onCustomImagePaste: print("foo") || textArea.customImagePaste()
    }
}
