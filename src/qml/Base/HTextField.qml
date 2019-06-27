import QtQuick 2.7
import QtQuick.Controls 2.2

TextField {
    property alias backgroundColor: textFieldBackground.color

    font.family: HStyle.fontFamily.sans
    font.pixelSize: HStyle.fontSize.normal

    color: HStyle.colors.foreground
    background: Rectangle {
        id: textFieldBackground
        color: HStyle.controls.textField.background
    }

    selectByMouse: true
}
