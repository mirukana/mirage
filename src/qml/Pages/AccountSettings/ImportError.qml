import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HBox {
    buttonModel: [
        { name: "retry", text: qsTr("Retry"), iconName: "retry" },
        { name: "cancel", text: qsTr("Cancel"), iconName: "cancel" },
    ]

    buttonCallbacks: ({
        retry: button => {
            encryptionUI.importKeys(
                accountInfo.import_error[0],
                accountInfo.import_error[1],
                button,
            )
        },
        cancel: button => { py.callClientCoro(userId, "clear_import_error") },
    })


    HLabel {
        color: theme.colors.errorText
        wrapMode: Text.Wrap
        text: qsTr("Couldn't import decryption keys file: %1")
              .arg(qsTr(accountInfo.import_error[2]))

        Layout.fillWidth: true
    }
}
