import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HBox {
    id: addChatBox
    clickButtonOnEnter: "apply"

    onFocusChanged: nameField.forceActiveFocus()

    buttonModel: [
        { name: "apply", text: qsTr("Create"), iconName: "room-create" },
        { name: "cancel", text: qsTr("Cancel"), iconName: "cancel" },
    ]

    buttonCallbacks: ({
        apply: button => {
            button.loading    = true
            errorMessage.text = ""

            let args = [
                nameField.text,
                topicField.text,
                publicCheckBox.checked,
                encryptCheckBox.checked,
                ! blockOtherServersCheckBox.checked,
            ]

            py.callClientCoro(userId, "new_group_chat", args, roomId => {
                button.loading = false
                pageLoader.showRoom(userId, roomId)

            }, (type, args) => {
                button.loading = false
                errorMessage.text =
                    qsTr("Unknown error - %1: %2").arg(type).arg(args)
            })
        },

        cancel: button => {
            nameField.text                    = ""
            topicField.text                   = ""
            publicCheckBox.checked            = false
            encryptCheckBox.checked           = false
            blockOtherServersCheckBox.checked = false

            pageLoader.showPrevious()
        }
    })


    readonly property string userId: addChatPage.userId


    HRoomAvatar {
        id: avatar
        clientUserId: userId
        displayName: nameField.text

        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: 128
        Layout.preferredHeight: Layout.preferredWidth

        CurrentUserAvatar {
            anchors.fill: parent
            z: 10
            opacity: nameField.text ? 0 : 1
            visible: opacity > 0

            Behavior on opacity { HNumberAnimation {} }
        }
    }

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

    EncryptCheckBox {
        id: encryptCheckBox

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
