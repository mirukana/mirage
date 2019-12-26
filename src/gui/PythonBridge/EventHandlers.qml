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

        delete py.privates.pendingCoroutines[uuid]

        if (error) {
            const type = py.getattr(py.getattr(error, "__class__"), "__name__")
            const args = py.getattr(error, "args")

            if (type === "CancelledError") {
                console.warn(`python: cancelled: ${uuid}`)
                return
            }

            if (onError) {
                onError(type, args, error, traceback)
                return
            }

            console.error(`python: ${uuid}\n${traceback}`)

            if (window.hideErrorTypes.has(type)) {
                console.warn(
                    "Not showing error popup for this type due to user choice"
                )
                return
            }

            utils.makePopup(
                "Popups/UnexpectedErrorPopup.qml",
                window,
                { errorType: type, errorArguments: args, traceback },
            )
        }

        if (onSuccess) onSuccess(result)
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
