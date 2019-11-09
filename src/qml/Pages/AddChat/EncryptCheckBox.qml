import QtQuick 2.12
import "../../Base"

HCheckBox {
    text: qsTr("Encrypt messages")
    subtitle.text:
        qsTr("Protect the room against eavesdropper. Only you " +
             "and those you trust can read the conversation.") +
        "<br><font color='" + theme.colors.middleBackground + "'>" +
        qsTr("Cannot be disabled later!") +
        "</font>"
    subtitle.textFormat: Text.StyledText
    spacing: addChatBox.horizontalSpacing
}
