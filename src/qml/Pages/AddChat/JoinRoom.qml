import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HBox {
    id: addChatBox
    clickButtonOnEnter: "join"

    onFocusChanged: roomField.forceActiveFocus()

    buttonModel: [
        { name: "apply", text: qsTr("Join"), iconName: "apply" },
        { name: "cancel", text: qsTr("Cancel"), iconName: "cancel" },
    ]

    buttonCallbacks: ({
        apply: button => {
            button.loading = true

            let args = [roomField.text]

            py.callClientCoro(userId, "room_join", args, roomId => {
                button.loading = false
                pageLoader.showRoom(userId, roomId)
            })
        },

        cancel: button => {
            roomField.text = ""
            pageLoader.showPrevious()
        }
    })


    readonly property string userId: addChatPage.userId


    HTextField {
        id: roomField
        placeholderText: qsTr("Alias (e.g. #example:matrix.org), URL or ID")

        Layout.fillWidth: true
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
