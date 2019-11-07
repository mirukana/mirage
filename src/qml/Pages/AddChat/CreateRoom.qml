import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HBox {
    id: addChatBox
    clickButtonOnEnter: "create"

    onFocusChanged: nameField.forceActiveFocus()

    buttonModel: [
        { name: "apply", text: qsTr("Create"), iconName: "apply" },
        { name: "cancel", text: qsTr("Cancel"), iconName: "cancel" },
    ]

    buttonCallbacks: ({
    })

    HTextField {
        id: nameField
        placeholderText: qsTr("Name")

        Layout.fillWidth: true
    }

    HTextField {
        id: topicField
        placeholderText: qsTr("Topic (optional)")

        Layout.fillWidth: true
    }

    HCheckBox {
        id: publicCheckBox
        text: qsTr("Make this room public")
        subtitle.text: qsTr("Anyone will be able to join without invitation.")
        spacing: addChatBox.horizontalSpacing

        Layout.maximumWidth: parent.width
    }

    HCheckBox {
        id: encryptCheckBox
        text: qsTr("Encrypt messages")
        subtitle.text:
            qsTr("Protect the room against eavesdropper. Only you " +
                 "and those you trust can read the conversation.") +
            "<br><font color='" + theme.colors.middleBackground + "'>" +
            qsTr("Cannot be disabled later!") +
            "</font>"
        subtitle.textFormat: Text.StyledText
        spacing: addChatBox.horizontalSpacing

        Layout.maximumWidth: parent.width
    }

    HCheckBox {
        id: blockOtherServersCheckBox
        text: qsTr("Reject users from other matrix servers")
        subtitle.text: qsTr("Cannot be changed later!")
        subtitle.color: theme.colors.middleBackground
        spacing: addChatBox.horizontalSpacing

        Layout.maximumWidth: parent.width
    }

    HLabel {
        id: errorMessage
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        color: theme.colors.errorText

        visible: Layout.maximumHeight > 0
        Layout.maximumHeight: text ? implicitHeight : 0
        Behavior on Layout.maximumHeight { HNumberAnimation {} }

        Layout.fillWidth: true
    }
}
