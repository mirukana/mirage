import QtQuick 2.12
import "../../Base"

HLoader {
    property bool importing: false


    function importKeys(file, passphrase, button=null) {
        if (button) button.loading = true
        importing = true

        let path = file.toString().replace(/^file:\/\//, "")

        py.callClientCoro(
            editAccount.userId, "import_keys", [path, passphrase], () => {
                importing = false
                if (button) button.loading = false
            }
        )
    }


    id: encryptionUI
    source:
        accountInfo.import_error[0] ? "ImportError.qml" :
        importing || accountInfo.total_keys_to_import ? "ImportingKeys.qml" :
        "ImportExportKeys.qml"

    onSourceChanged: animation.running = true

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
