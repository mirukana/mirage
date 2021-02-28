import QtQuick 2.12
import QtQuick.Controls 2.12

ComboBox {
    id: root

    property bool error: false
    property bool bordered: true
    property color backgroundColor: theme.controls.textField.background
    property color borderColor: theme.controls.textField.border
    property color errorBorder: theme.controls.textField.errorBorder
    property color focusedBorderColor: theme.controls.textField.focusedBorder
    property color focusedBackgroundColor:
        theme.controls.textField.focusedBackground

    spacing: 0

    background: Rectangle {
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

    contentItem: HTextField {
        id: field
        background: null
        text: root.displayText
        readOnly: ! root.editable
        rightPadding: root.indicator.width + theme.spacing

        TapHandler {
            enabled: field.readOnly
            onTapped:
                root.popup.visible ? root.popup.close() : root.popup.open()
        }
    }

    indicator: HButton {
        x: root.width - root.rightPadding
        height: root.availableHeight
        backgroundColor: "transparent"
        icon.name: "combo-box-" + (root.popup.visible ? "close" : "open")
        iconItem.small: true
        onClicked: root.popup.visible ? root.popup.close() : root.popup.open()
    }

    popup: HMenu {
        id: menu
        y: root.height
        width: root.width
        modal: false
        onOpened: currentIndex = root.currentIndex

        enter: Transition {
            HNumberAnimation {
                property: "height"
                from: 0
                to: menu.implicitHeight
                easing.type: Easing.OutQuad
            }
        }

        exit: Transition {
            HNumberAnimation {
                property: "height"
                to: 0
                easing.type: Easing.InQuad
            }
        }

        HLabel {
            visible: root.editable
            height: visible ? implicitHeight : 0
            text: qsTr("Custom input accepted")
            color: theme.colors.dimText
            leftPadding: theme.spacing
            rightPadding: leftPadding
            topPadding: theme.spacing / 1.75
            bottomPadding: topPadding
            width: menu.width
            wrapMode: HLabel.Wrap
        }

        Repeater {
            model: root.popup.visible ? root.model : null
            delegate: root.delegate
        }
    }

    delegate: HMenuItem {
        text: modelData
        onTriggered: root.currentIndex = model.index
    }
}
