// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

QtObject {
    function onExitRequested(exitCode) {
        Qt.exit(exitCode)
    }


    function onAlertRequested() {
        if (Qt.application.state !== Qt.ApplicationActive) {
            window.alert(window.settings.alertOnMessageForMsec)
        }
    }


    function onCoroutineDone(uuid, result, error, traceback) {
        let onSuccess = py.privates.pendingCoroutines[uuid].onSuccess
        let onError   = py.privates.pendingCoroutines[uuid].onError

        if (error) {
            let type = py.getattr(py.getattr(error, "__class__"), "__name__")
            let args = py.getattr(error, "args")

            type === "CancelledError" ?
            console.warn(`python: cancelled: ${uuid}`) :

            onError ?
            onError(type, args, error, traceback) :

            console.error(`python: ${uuid}\n${traceback}`)

        } else if (onSuccess) { onSuccess(result) }

        delete py.privates.pendingCoroutines[uuid]
    }


    function onModelUpdated(syncId, data, serializedSyncId) {
        if (serializedSyncId === "Account" || serializedSyncId[0] === "Room") {
            py.callCoro("get_flat_mainpane_data", [], data => {
                window.mainPaneModelSource = data
            })
        }

        window.modelSources[serializedSyncId] = data
        window.modelSourcesChanged()
    }
}
