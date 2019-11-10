import QtQuick 2.12
import "../../Base"

HLoader {
    id: encryptionUI
    source:
        accountInfo.import_error[0]      ? "ImportError.qml" :
        accountInfo.total_keys_to_import ? "ImportingKeys.qml" :
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
