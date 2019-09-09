import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HBox {
    horizontalSpacing: currentSpacing
    verticalSpacing: currentSpacing

    buttonModel: [
        { name: "export", text: qsTr("Export"), iconName: "export-keys"},
        { name: "import", text: qsTr("Import"), iconName: "import-keys"},
    ]

    buttonCallbacks: ({
        export: button => {
            Utils.makeObject(
                "Dialogs/ExportKeys.qml",
                editAccount,
                { userId: editAccount.userId },
                obj => {
                    button.loading = Qt.binding(() => obj.exporting)
                    obj.dialog.open()
                }
            )
        },
        import: button => {
            Utils.makeObject(
                "Dialogs/ImportKeys.qml",
                editAccount,
                { userId: editAccount.userId },
                obj => { obj.dialog.open() }
            )
        },
    })


    HLabel {
        wrapMode: Text.Wrap
        text: qsTr(
            "The decryption keys for messages you received in encrypted " +
            "rooms can be exported to a passphrase-protected file.\n\n" +

            "You can then import this file on any Matrix account or " +
            "client, to be able to decrypt these messages again."
        )

        Layout.fillWidth: true
    }
}
