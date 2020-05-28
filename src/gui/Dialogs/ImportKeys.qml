// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt.labs.platform 1.1
import "../Popups"
import "../PythonBridge"

HFileDialogOpener {
    fill: false
    dialog.title: qsTr("Select a decryption keys file to import")
    onFilePicked: {
        importPasswordPopup.file = file
        importPasswordPopup.open()
    }


    property string userId: ""
    property bool importing: false
    property Future importFuture: null


    PasswordPopup {
        id: importPasswordPopup
        details.text:
            importing ?
            qsTr("This might take a while...") :
            qsTr("Passphrase used to protect this file:")
        okText: qsTr("Import")

        onClosed: if (importFuture) importFuture.cancel()


        property url file: ""


        function verifyPassword(pass, callback) {
            importing  = true

            const call = py.callClientCoro
            const path = file.toString().replace(/^file:\/\//, "")

            importFuture = call(userId, "import_keys", [path, pass], () => {
                importing    = false
                importFuture = null
                callback(true)

            }, (type, args, error, traceback, uuid) => {
                let unknown  = false
                importFuture = null

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

                    (
                        unknown = true,
                        qsTr("Unknown error: %1 - %2").arg(type).arg(args)
                    )
                )

                if (unknown) utils.showError(type, traceback, uuid)
            })
        }


        Binding on closePolicy {
            value: Popup.CloseOnEscape
            when: importing
        }
    }
}
