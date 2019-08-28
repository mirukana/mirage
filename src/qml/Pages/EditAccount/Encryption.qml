import QtQuick 2.12
import "../../Base"

HLoader {
    id: loader
    source: accountInfo.total_keys_to_import ?
            "ImportingKeys.qml" : "ImportExportKeys.qml"

    onSourceChanged: animation.running = true

    HNumberAnimation {
        id: animation
        target: loader.item
        property: "scale"
        from: 0
        to: 1
        overshoot: 3
    }
}
