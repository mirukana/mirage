// SPDX-License-Identifier: LGPL-3.0-or-later

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


    property string userId: ""
    property bool importing: false


    PasswordPopup {
        id: importPasswordPopup
        details.text: qsTr(
            "Please enter the passphrase that was used to protect this file:"
        )
        okText: qsTr("Import")


        property url file: ""


        function verifyPassword(pass, callback) {
            importing = true
            let path  = file.toString().replace(/^file:\/\//, "")

            py.callClientCoro(userId, "import_keys", [path, pass], () => {
                importing = false
                callback(true)

            }, (type, args) => {
                callback(
                    type === "EncryptionError" ?
                    false :

                    type === "ValueError" ?
                    qsTr("Invalid file format") :

                    type === "FileNotFoundError" ?
                    qsTr("This file doesn't exist") :

                    type === "IsADirectoryError" ?
                    qsTr("A folder was given, expecting a file") :

                    type === "PermissionError" ?
                    qsTr("No permission to read this file") :

                    qsTr("Unknown error: %1 - %2").arg(type).arg(args)
                )
            })
        }
    }
}
