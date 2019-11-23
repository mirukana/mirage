import QtQuick 2.12
import Qt.labs.platform 1.1
import "../Popups"

HFileDialogOpener {
    fill: false
    dialog.title: qsTr("Select a decryption keys file to import")
    onFilePicked: {
        importPasswordPopup.file = file
        importPasswordPopup.open()
    }


    signal done()


    property string userId: ""
    property bool importing: false


    function importKeys(file, passphrase) {
        importing = true

        let path = file.toString().replace(/^file:\/\//, "")
        py.callClientCoro(userId, "import_keys", [path, passphrase], () => {
            importing = false
            done()
        })
    }


    PasswordPopup {
        id: importPasswordPopup
        details.text: qsTr(
            "Please enter the passphrase that was used to protect this file:"
        )
        okText: qsTr("Import")

        onAcceptedPasswordChanged: importKeys(file, acceptedPassword)

        property url file: ""

        function verifyPassword(pass, callback) {
            py.callCoro(
                "check_exported_keys_passphrase",
                [file.toString().replace(/^file:\/\//, ""), pass],
                callback
            )
        }
    }
}
