// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

TextArea {
    id: textArea


    property string saveName: ""
    property var saveId: "ALL"
    property var saveProperties: ["text"]

    property var focusItemOnTab: null
    property var disabledText: null
    property string defaultText: ""
    readonly property bool changed: text !== defaultText

    property alias backgroundColor: textAreaBackground.color


    function reset() { clear(); text = Qt.binding(() => defaultText) }
    function insertAtCursor(text) { insert(cursorPosition, text) }


    text: defaultText
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
        color: theme.controls.textArea.background
        radius: theme.radius
    }

    // Set it only on component creation to avoid binding loops
    Component.onCompleted: if (! text) {
        text                    = window.getState(this, "text", "")
        textArea.cursorPosition = text.length
    }

    onActiveFocusChanged:
        text = activeFocus || changed ? text : Qt.binding(() => defaultText)

    onTextChanged: window.saveState(this)

    Keys.onPressed: if (
        event.modifiers & Qt.AltModifier ||
        event.modifiers & Qt.MetaModifier
    ) event.accepted = true

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
