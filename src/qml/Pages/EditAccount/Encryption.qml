// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

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
            "The decryption keys for the messages you received in " +
            "encrypted rooms can be exported to a file.%1" +
            "You will then be able to import this file in another " +
            "Matrix client."
        ).arg(pageStack.isWide ? "\n" :"\n\n")

        Layout.fillWidth: true
        Layout.margins: currentSpacing
    }

    HRowLayout {
        HUIButton {
            id: exportButton
            iconName: "export-keys"
            text: qsTr("Export")
            enabled: false

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom
        }

        HUIButton {
            id: importButton
            iconName: "import-keys"
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

        id: importPasswordPopup
        label.text: qsTr(
            "Please enter the passphrase that was used to protect this " +
            "file.\n\n" +
            "The import can take a few minutes. " +
            "You can leave the account settings page while it is running. " +
            "Messages may not be sent or received until the operation is done."
        )
        onPasswordChanged: importKeys(file, password)
    }
}
