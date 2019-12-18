import QtQuick 2.12
import "../../Base"

HCheckBox {
    text: qsTr("Encrypt messages")
    subtitle.text:
        qsTr("Only you and those you trust will be able to read the " +
             "conversation") +
        `<br><font color="${theme.colors.middleBackground}">` +
        qsTr("Cannot be disabled later!") +
        "</font>"
    subtitle.textFormat: Text.StyledText
}
