import QtQuick 2.12
import "../../Base"

HLoader {
    id: encryptionUI
    source:
        accountInfo.import_error[0] ? "ImportError.qml" :
        importing || accountInfo.total_keys_to_import ? "ImportingKeys.qml" :
        "ImportExportKeys.qml"

    onSourceChanged: animation.running = true


    property bool importing: false


    function exportKeys(file, passphrase, button=null) {
        if (button) button.loading = true

        let path = file.toString().replace(/^file:\/\//, "")

        py.callClientCoro(
            editAccount.userId, "export_keys", [path, passphrase], () => {
                // null: user is on another page
                if (encryptionUI !== null && button) button.loading = false
            }
        )
    }

    function importKeys(file, passphrase, button=null) {
        if (button) button.loading = true
        encryptionUI.importing = true

        let path = file.toString().replace(/^file:\/\//, "")

        py.callClientCoro(
            editAccount.userId, "import_keys", [path, passphrase], () => {
                if (encryptionUI !== null) {
                    encryptionUI.importing = false
                    if (button) button.loading = false
                }
            }
        )
    }


    SequentialAnimation {
        id: animation
        HNumberAnimation {
            target: encryptionUI; property: "scale"; to: 0;
        }
        HNumberAnimation {
            target: encryptionUI; property: "scale"; to: 1; overshoot: 3;
        }
    }
}
