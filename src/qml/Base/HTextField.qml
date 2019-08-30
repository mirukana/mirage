import QtQuick 2.12
import QtQuick.Controls 2.12

TextField {
    id: field
    leftPadding: theme.spacing
    rightPadding: leftPadding
    topPadding: theme.spacing / 1.5
    bottomPadding: topPadding

    font.family: theme.fontFamily.sans
    font.pixelSize: theme.fontSize.normal
    font.pointSize: -1

    readonly property QtObject _tf: theme.controls.textField

    property bool error: false

    property bool bordered: true
    property color backgroundColor: _tf.background
    property color borderColor: _tf.border
    property color errorBorder: _tf.errorBorder
    property color focusedBackgroundColor: _tf.focusedBackground
    property color focusedBorderColor: _tf.focusedBorder
    property alias radius: textFieldBackground.radius

    color: activeFocus ? _tf.focusedText : _tf.text

    background: Rectangle {
        id: textFieldBackground
        color: field.activeFocus ? focusedBackgroundColor : backgroundColor
        border.color: error ? errorBorder :
                      field.activeFocus ? focusedBorderColor : borderColor
        border.width: bordered ? theme.controls.textField.borderWidth : 0

        Behavior on color { HColorAnimation { factor: 0.25 } }
        Behavior on border.color { HColorAnimation { factor: 0.25 } }
    }

    selectByMouse: true

    Keys.onPressed: if (
        event.modifiers & Qt.AltModifier ||
        event.modifiers & Qt.MetaModifier
    ) event.accepted = true

    Keys.forwardTo: mainUI.shortcuts
}
