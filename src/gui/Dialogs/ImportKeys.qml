// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt.labs.platform 1.1
import "../Popups"

HFileDialogOpener {
    property string userId: ""
    property string importFutureId: ""


    fill: false
    dialog.title: qsTr("Select a decryption keys file to import")
    onFilePicked: {
        importPasswordPopup.file = file
        importPasswordPopup.open()
    }

    PasswordPopup {
        id: importPasswordPopup

        property url file: ""

        function verifyPassword(pass, callback) {
            const call = py.callClientCoro
            const path = file.toString().replace(/^file:\/\//, "")

            importFutureId = call(userId, "import_keys", [path, pass], () => {
                importFutureId = ""
                callback(true)

            }, (type, args, error, traceback, uuid) => {
                let unknown    = false
                importFutureId = ""

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

                if (unknown) py.showError(type, traceback, uuid)
            })
        }

        summary.text:
            importFutureId ?
            qsTr("This might take a while...") :
            qsTr("Passphrase used to protect this file:")
        validateButton.text: qsTr("Import")
        validateButton.icon.name: "import-keys"

        onClosed: if (importFutureId) py.cancelCoro(importFutureId)

        Binding on closePolicy {
            value: Popup.CloseOnEscape
            when: importFutureId
        }
    }
}
