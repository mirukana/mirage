import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HBox {
    id: signInBox
    clickButtonOnEnter: "ok"

    buttonModel: [
        { name: "ok", text: qsTr("Register from Riot"), iconName: "register" },
    ]

    buttonCallbacks: ({
        ok: button => {
            Qt.openUrlExternally("https://riot.im/app/#/register")
        }
    })


    HLabel {
        wrapMode: Text.Wrap
        text: qsTr(
            "Registering is not implemented yet. You can create a new " +
            "account from a client that supports it, such as Riot."
        )

        Layout.fillWidth: true
    }
}
