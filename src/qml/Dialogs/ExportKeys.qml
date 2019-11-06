import QtQuick 2.12
import Qt.labs.platform 1.1
import "../Popups"

HFileDialogOpener {
    fill: false
    dialog.title: qsTr("Save decryption keys file as...")
    dialog.fileMode: FileDialog.SaveFile
    onFilePicked: {
        exportPasswordPopup.file = file
        exportPasswordPopup.open()
    }


    signal done()


    property string userId: ""
    property bool exporting: false


    function exportKeys(file, passphrase) {
        exporting = true

        let path = file.toString().replace(/^file:\/\//, "")

        py.callClientCoro(userId, "export_keys", [path, passphrase], () => {
            exporting = false
            done()
        })
    }


    PasswordPopup {
        id: exportPasswordPopup
        details.text: qsTr("Please enter a passphrase to protect this file:")
        okText: qsTr("Export")

        onAcceptedPasswordChanged: exportKeys(file, acceptedPassword)

        property url file: ""
    }
}
