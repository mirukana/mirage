import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HColumnLayout {
    function importKeys(file, passphrase) {
        importButton.loading = true

        let path = Qt.resolvedUrl(file).replace(/^file:\/\//, "")

        py.callClientCoro(
            editAccount.userId, "import_keys", [path, passphrase], () => {
                importButton.loading = false
            }
        )
    }

    HLabel {
        wrapMode: Text.Wrap
        text: qsTr(
            "The decryption keys for messages you received in encrypted " +
            "rooms can be exported to a passphrase-protected file.%1" +
            "You will then be able to import this file in another " +
            "Matrix client."
        ).arg(pageLoader.isWide ? "\n" :"\n\n")

        Layout.fillWidth: true
        Layout.margins: currentSpacing
    }

    HRowLayout {
        HButton {
            id: exportButton
            icon.name: "export-keys"
            text: qsTr("Export")
            enabled: false

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom
        }

        HButton {
            id: importButton
            icon.name: "import-keys"
            text: qsTr("Import")

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom

            HFileDialogOpener {
                id: fileDialog
                dialog.title: qsTr("Select a decryption key file to import")
                onFileChanged: {
                    importPasswordPopup.file = file
                    importPasswordPopup.open()
                }
            }
        }
    }

    HPasswordPopup {
        property url file: ""

        function verifyPassword(pass) {
            return py.callSync(
                "check_exported_keys_password", [file.toString(), pass]
            )
        }

        id: importPasswordPopup
        label.text: qsTr(
            "Please enter the passphrase that was used to protect this file:"
        )
        onAcceptedPasswordChanged: importKeys(file, password)
    }
}
